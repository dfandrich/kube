/*
    Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
    Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
    Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Library General Public License as published by
    the Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
    License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to the
    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301, USA.
*/

#include "eventoccurrencemodel.h"

#include <sink/log.h>
#include <sink/query.h>
#include <sink/store.h>
#include <sink/applicationdomaintype.h>

#include <QMetaEnum>

#include <KCalCore/ICalFormat>
#include <KCalCore/OccurrenceIterator>
#include <KCalCore/MemoryCalendar>

#include <entitycache.h>

using namespace Sink;

EventOccurrenceModel::EventOccurrenceModel(QObject *parent)
    : QAbstractItemModel(parent),
    mCalendarCache{EntityCache<ApplicationDomain::Calendar, ApplicationDomain::Calendar::Color>::Ptr::create()},
    mCalendar{new KCalCore::MemoryCalendar{QTimeZone::systemTimeZone()}}
{
    mRefreshTimer.setSingleShot(true);
    QObject::connect(&mRefreshTimer, &QTimer::timeout, this, &EventOccurrenceModel::updateFromSource);
}

void EventOccurrenceModel::setStart(const QDate &start)
{
    if (start != mStart) {
        mStart = start;
        updateQuery();
    }
}

QDate EventOccurrenceModel::start() const
{
    return mStart;
}

void EventOccurrenceModel::setLength(int length)
{
    mLength = length;
    updateQuery();
}

int EventOccurrenceModel::length() const
{
    return mLength;
}

void EventOccurrenceModel::setCalendarFilter(const QSet<QByteArray> &calendarFilter)
{
    mCalendarFilter = calendarFilter;
    updateQuery();
}

void EventOccurrenceModel::setFilter(const QVariantMap &filter)
{
    mFilter = filter;
    updateQuery();
}

void EventOccurrenceModel::updateQuery()
{
    using namespace Sink::ApplicationDomain;
    if (mCalendarFilter.isEmpty() || !mLength || !mStart.isValid()) {
        refreshView();
        return;
    }
    mEnd = mStart.addDays(mLength);

    Sink::Query query;
    query.setFlags(Sink::Query::LiveQuery);
    query.request<Event::Summary>();
    query.request<Event::Description>();
    query.request<Event::StartTime>();
    query.request<Event::EndTime>();
    query.request<Event::Calendar>();
    query.request<Event::Ical>();
    query.request<Event::AllDay>();

    query.filter<Event::StartTime, Event::EndTime>(Sink::Query::Comparator(QVariantList{mStart, mEnd}, Sink::Query::Comparator::Overlap));

    mSourceModel = Store::loadModel<ApplicationDomain::Event>(query);

    QObject::connect(mSourceModel.data(), &QAbstractItemModel::dataChanged, this, &EventOccurrenceModel::refreshView);
    QObject::connect(mSourceModel.data(), &QAbstractItemModel::layoutChanged, this, &EventOccurrenceModel::refreshView);
    QObject::connect(mSourceModel.data(), &QAbstractItemModel::modelReset, this, &EventOccurrenceModel::refreshView);
    QObject::connect(mSourceModel.data(), &QAbstractItemModel::rowsInserted, this, &EventOccurrenceModel::refreshView);
    QObject::connect(mSourceModel.data(), &QAbstractItemModel::rowsMoved, this, &EventOccurrenceModel::refreshView);
    QObject::connect(mSourceModel.data(), &QAbstractItemModel::rowsRemoved, this, &EventOccurrenceModel::refreshView);

    refreshView();
}

void EventOccurrenceModel::refreshView()
{
    if (!mRefreshTimer.isActive()) {
        //Instant update, but then only refresh every 50ms max.
        updateFromSource();
        mRefreshTimer.start(50);
    }
}

void EventOccurrenceModel::updateFromSource()
{
    beginResetModel();

    mEvents.clear();

    if (mSourceModel) {
        for (int i = 0; i < mSourceModel->rowCount(); ++i) {
            auto event = mSourceModel->index(i, 0).data(Sink::Store::DomainObjectRole).value<ApplicationDomain::Event::Ptr>();
            const bool skip = [&] {
                if (!mCalendarFilter.contains(event->getCalendar())) {
                    return true;
                }
                for (auto it = mFilter.constBegin(); it!= mFilter.constEnd(); it++) {
                    if (event->getProperty(it.key().toLatin1()) != it.value()) {
                        return true;
                    }
                }
                return false;
            }();
            if (skip) {
                continue;
            }

            //Parse the event
            auto icalEvent = KCalCore::ICalFormat().readIncidence(event->getIcal()).dynamicCast<KCalCore::Event>();
            if(!icalEvent) {
                SinkWarning() << "Invalid ICal to process, ignoring...";
                continue;
            }

            if (icalEvent->recurs()) {
                KCalCore::OccurrenceIterator occurrenceIterator{*mCalendar, icalEvent, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};
                while (occurrenceIterator.hasNext()) {
                    occurrenceIterator.next();
                    const auto start = occurrenceIterator.occurrenceStartDate();
                    const auto end = icalEvent->endDateForStart(start);
                    if (start.date() < mEnd && end.date() >= mStart) {
                        mEvents.append({start, end, occurrenceIterator.incidence(), getColor(event->getCalendar()), event->getAllDay(), event});
                    }
                }
            } else {
                if (icalEvent->dtStart().date() < mEnd && icalEvent->dtEnd().date() >= mStart) {
                    mEvents.append({icalEvent->dtStart(), icalEvent->dtEnd(), icalEvent, getColor(event->getCalendar()), event->getAllDay(), event});
                }
            }
        }
    }

    endResetModel();
}

QModelIndex EventOccurrenceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    if (!parent.isValid()) {
        return createIndex(row, column);
    }
    return {};
}

QModelIndex EventOccurrenceModel::parent(const QModelIndex &) const
{
    return {};
}

int EventOccurrenceModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        return mEvents.size();
    }
    return 0;
}

int EventOccurrenceModel::columnCount(const QModelIndex &) const
{
    return 1;
}

QByteArray EventOccurrenceModel::getColor(const QByteArray &calendar) const
{
    const auto color = mCalendarCache->getProperty(calendar, "color").toByteArray();
    if (color.isEmpty()) {
        qWarning() << "Failed to get color for calendar " << calendar;
    }
    return color;
}

QVariant EventOccurrenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    auto event = mEvents.at(idx.row());
    auto icalEvent = event.incidence;
    switch (role) {
        case Summary:
            return icalEvent->summary();
        case Description:
            return icalEvent->description();
        case StartTime:
            return event.start;
        case EndTime:
            return event.end;
        case Color:
            return event.color;
        case AllDay:
            return event.allDay;
        case Event:
            return QVariant::fromValue(event.domainObject);
        case EventOccurrence:
            return QVariant::fromValue(event);
        default:
            SinkWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}


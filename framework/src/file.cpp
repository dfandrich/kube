/*
    Copyright (c) 2017 Christian Mollekopf <mollekopf@kolabsys.com>

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

#include "file.h"
#include <QFile>
#include <QDir>
#include <QUrl>
#include <QDebug>

using namespace Kube;

QString File::data()
{
    auto s = read(mPath);
    if (s.isEmpty()) {
        return mDefaultContent;
    }
    return s;
}

QString File::read(const QString &path)
{
    QFile file(QDir::homePath() + "/" + path);
    if (file.open(QIODevice::ReadOnly)) {
        return file.readAll();
    }
    qWarning() << "Failed to open the file " << file.fileName() << file.errorString();
    return {};
}

/*
 *  Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.3

import org.kube.framework 1.0 as Kube
import "dateutils.js" as DateUtils

FocusScope {
    id: root
    property var controller

    width: stackView.width
    height: stackView.height

    signal done()

    StackView {
        id: stackView
        anchors.centerIn: parent
        width: stackView.currentItem.implicitWidth
        height: stackView.currentItem.implicitHeight
        initialItem: eventDetails
        clip: true
    }

    Component {
        id: eventDetails
        Rectangle {
            implicitWidth: contentLayout.implicitWidth + 2 * Kube.Units.largeSpacing
            implicitHeight: contentLayout.implicitHeight + 2 * Kube.Units.largeSpacing
            color: Kube.Colors.viewBackgroundColor

            ColumnLayout {
                id: contentLayout
                anchors {
                    centerIn: parent
                }

                spacing: Kube.Units.smallSpacing

                Kube.Heading {
                    Layout.fillWidth: true
                    text: controller.summary
                }

                Kube.SelectableLabel {
                    visible: controller.allDay
                    text: controller.start.toLocaleString(Qt.locale(), "dd. MMMM") + (DateUtils.sameDay(controller.start, controller.end) ? "" : " - " + controller.end.toLocaleString(Qt.locale(), "dd. MMMM"))
                }

                Kube.SelectableLabel {
                    visible: !controller.allDay
                    text: controller.start.toLocaleString(Qt.locale(), "dd. MMMM hh:mm") + " - " + (DateUtils.sameDay(controller.start, controller.end) ? controller.end.toLocaleString(Qt.locale(), "hh:mm") : controller.end.toLocaleString(Qt.locale(), "dd. MMMM hh:mm"))
                }

                Kube.SelectableLabel {
                    visible: controller.recurring
                    text: qsTr("repeats %1").arg(controller.recurrenceString)
                }

                Kube.SelectableLabel {
                    text: "@" + controller.location
                    visible: controller.location
                }

                Kube.SelectableLabel {
                    text: qsTr("Organizer: %1").arg(controller.organizer)
                    visible: controller.organizer
                }

                Flow {
                    visible: attendeeRepeater.count
                    height: contentHeight
                    spacing: Kube.Units.smallSpacing
                    Kube.SelectableLabel {
                        text: qsTr("Attending:")
                        visible: controller.organizer
                    }
                    Repeater {
                        id: attendeeRepeater
                        model: controller.attendees.model
                        delegate: Kube.Label {
                            text: qsTr("%1").arg(model.name) + (index == (attendeeRepeater.count - 1) ? "" : ",")
                            elide: Text.ElideRight
                        }
                    }
                }

                Kube.TextArea {
                    Layout.fillWidth: true
                    text: controller.description
                }

                Item {
                    width: 1
                    height: Kube.Units.largeSpacing
                }

                RowLayout {
                    Kube.Button {
                        text: qsTr("Remove")
                        onClicked: {
                            root.controller.remove()
                            root.done()
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Kube.Button {
                        enabled: controller.ourEvent
                        text: qsTr("Edit")
                        onClicked: {
                            stackView.push(editor, StackView.Immediate)
                        }
                    }

                }
            }
        }
    }

    Component {
        id: editor
        EventEditor {
            controller: root.controller
            editMode: true
            onDone: root.done()
        }
    }
}

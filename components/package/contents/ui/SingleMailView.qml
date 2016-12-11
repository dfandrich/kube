/*
 *  Copyright (C) 2016 Michael Bohlender, <michael.bohlender@kdemail.net>
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

import QtQuick 2.7
import QtQuick.Controls 1.3 as Controls1
import QtQuick.Controls 2
import QtQuick.Layouts 1.1
import org.kde.kirigami 1.0 as Kirigami

import QtQml 2.2 as QtQml

import org.kube.framework.domain 1.0 as KubeFramework

Item {
    id: root

    property variant mail;

    Rectangle {
        id: subjectBar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Kirigami.Units.gridUnit * 2

        color: Kirigami.Theme.backgroundColor

        Kirigami.Heading {
            anchors.centerIn: parent

            width: parent.width - Kirigami.Units.gridUnit * 4.2

            text: "Some subject"
            color: Kirigami.Theme.textColor
            level: 4
            font.italic: true

        }

        Button {
            anchors {
                right: parent.right
                rightMargin: Kirigami.Units.gridUnit * 0.2
                verticalCenter: parent.verticalCenter
            }
            text: "show plaintext"

            onClicked: {
                text = text == "show plaintext" ? "show html" : "show plaintext"
                focus = false
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom

            height: 1
            width: parent.width

            color: Kirigami.Theme.highlightColor
        }
    }


    ListView {
        anchors {
            top: subjectBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        clip: true

        model: KubeFramework.MailListModel {
            mail: root.mail
        }

        header: Item {
            height: Kirigami.Units.gridUnit
            width: parent.width

        }

        footer: Item {
            height: Kirigami.Units.gridUnit * 2
            width: parent.width
        }

        delegate: Item {

            height: sheet.height + Kirigami.Units.gridUnit * 2
            width: parent.width

            Rectangle {
                id: sheet
                anchors.centerIn: parent
                implicitHeight: header.height + body.height + (Kirigami.Units.gridUnit * 2.5) * 2 + footer.height
                width: parent.width - Kirigami.Units.gridUnit * 4

                color: Kirigami.Theme.viewBackgroundColor

                //BEGIN header
                Item {
                    id: header

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: Kirigami.Units.largeSpacing
                    }

                    height: from.height + to.height + Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

                    Avatar {
                        id: avatar

                        anchors {
                            top: parent.top
                            topMargin: Kirigami.Units.smallSpacing
                        }

                        height: Kirigami.Units.gridUnit * 2.5
                        width: height

                        name: model.senderName
                    }

                    Row{
                        id: from

                        anchors {
                            top: avatar.top
                            left: avatar.right
                            leftMargin: Kirigami.Units.smallSpacing * 2
                            topMargin: Kirigami.Units.smallSpacing
                        }

                        width: parent.width - avatar.width - Kirigami.Units.largeSpacing * 3

                        spacing: Kirigami.Units.smallSpacing
                        clip: true

                        Text {
                            id: senderName

                            text: model.senderName

                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                            opacity: 0.75
                        }

                        Text {

                            width: parent.width - senderName.width - Kirigami.Units.smallSpacing

                            text: model.sender

                            color: Kirigami.Theme.textColor
                            opacity: 0.75

                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: to_label

                        anchors {
                            top: from.bottom
                            left: avatar.right
                            leftMargin: Kirigami.Units.smallSpacing * 2
                            topMargin: Kirigami.Units.smallSpacing * 0.5
                        }

                        text: "to:"

                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                    }

                    Text {
                        id: to

                        anchors {
                            top: to_label.top
                            left: to_label.right
                            leftMargin: Kirigami.Units.smallSpacing
                        }

                        width: parent.width - avatar.width  - to_label.width - Kirigami.Units.largeSpacing * 2

                        text: model.to + " "  + model.cc + " " +  model.bcc

                        maximumLineCount: 3
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideRight

                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                        clip: true
                    }

                    Text {

                        anchors {
                            right: seperator.right
                            bottom: headerContent.top
                        }

                        text: Qt.formatDateTime(model.date, "dd MMM yyyy hh:mm")

                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.7
                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                    }

                    Rectangle {
                        anchors {
                            bottom: seperator.top
                            right: seperator.right
                        }

                        height: Kirigami.Units.gridUnit
                        width: height

                        color: Kirigami.Theme.backgroundColor

                        Controls1.ToolButton {
                            anchors.fill: parent

                            iconName: "go-down"
                        }
                    }

                    Rectangle {
                        id: seperator

                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }

                        height: 1

                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                    }
                }
                //END header

                Flow {
                    id: attachments

                    anchors {
                        top: header.bottom
                        topMargin: Kirigami.Units.smallSpacing
                        horizontalCenter: parent.horizontalCenter
                    }

                    width: parent.width - Kirigami.Units.gridUnit * 2
                    height: Kirigami.Units.gridUnit * 2

                    layoutDirection: Qt.RightToLeft
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: body.attachments

                        delegate: AttachmentDelegate {
                            name: model.name
                            icon: "mail-attachment"

                            //TODO size encrypted signed type
                        }
                    }
                }

                MailViewer {
                    id: body

                    anchors {
                        top: header.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: avatar.height + Kirigami.Units.gridUnit
                        rightMargin: avatar.height + Kirigami.Units.gridUnit
                        topMargin: avatar.height
                    }

                    width: header.width - Kirigami.Units.largeSpacing * 2
                    height: desiredHeight

                    message: model.mimeMessage
                }

                Item {
                    id: footer

                    anchors.bottom: parent.bottom

                    height: Kirigami.Units.gridUnit * 2
                    width: parent.width

                    Text {

                        anchors{
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: Kirigami.Units.gridUnit
                        }

                        text: "Delete Mail"
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                    }

                    Controls1.ToolButton {
                        anchors{
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: Kirigami.Units.gridUnit
                        }

                        iconName: "mail-reply-sender"
                    }
                }
            }
        }
    }
}

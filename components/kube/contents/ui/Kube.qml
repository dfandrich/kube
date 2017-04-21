/*
 *  Copyright (C) 2017 Michael Bohlender, <michael.bohlender@kdemail.net>
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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

import QtQuick.Controls 2.0 as Controls2

import org.kube.framework 1.0 as Kube
import org.kube.components.accounts 1.0 as KubeAccounts

Controls2.ApplicationWindow {
    id: app

    //FIXME remove fixed pixel hight
    //for now just convinience during testing
    height: 1080 * 0.8
    width: 1920  * 0.8

    visible: true

    Kube.NotificationHandler {
        id: notificationHandler
        function handler(n) {
            console.warn("We got a notification: ", n.message)
            if (n.type == Kube.Notification.Warning) {
                console.warn("And it's a warning!", n.type)
            }
            notificationPopup.notify(n.message);
        }
    }

    //BEGIN Actions
    Kube.Context {
        id: maillistcontext
        property variant mail
        property bool isDraft
        mail: mailListView.currentMail
        isDraft: mailListView.isDraft
    }

    Kube.Action {
        id: replyAction
        actionId: "org.kde.kube.actions.reply"
        context: maillistcontext
    }
    //END Actions

    //BEGIN ActionHandler
    Kube.ActionHandler {
        actionId: "org.kde.kube.actions.reply"
        function isReady(context) {
            return context.mail ? true : false;
        }

        function handler(context) {
            composer.loadMessage(context.mail, false)
            composer.open()
        }
    }

    Kube.ActionHandler {
        actionId: "org.kde.kube.actions.edit"
        function isReady(context) {
            return context.mail && context.isDraft;
        }
        function handler(context) {
            composer.loadMessage(context.mail, true)
            composer.open()
        }
    }
    //END ActionHandler

    //Controller
    Kube.FolderController {
        id: folderController
        Binding on folder {
            //!! checks for the availability of the type
            when: !!folderListView.currentFolder
            value: folderListView.currentFolder
        }
    }

    //Model
    Kube.AccountsModel {
        id: currentAccountModel
        accountId: accountFolderview.accountId
    }

    //BEGIN Shortcuts
    Shortcut {
        sequence: StandardKey.Refresh
        onActivated: folderController.synchronizeAction.execute()
        enabled: folderController.synchronizeAction.enabled
    }
    //END Shortcuts

    //BEGIN background
    Rectangle {
        anchors.fill: parent

        color: Kube.Colors.backgroundColor
    }
    //END background

    //BEGIN Main content
    RowLayout  {
        spacing: 0

        width: parent.width

        Rectangle {
            id: sideBar

            width: Kube.Units.gridUnit + Kube.Units.largeSpacing
            height: app.height
            color: "#232629"//Kube.Colors.textColor

            Column {
                anchors {
                    top: parent.top
                    topMargin: Kube.Units.largeSpacing
                    horizontalCenter: parent.horizontalCenter
                }

                spacing: Kube.Units.largeSpacing - Kube.Units.smallSpacing

                ToolButton {
                    iconName: Kube.Icons.search_inverted
                    height: Kube.Units.gridUnit * 1.5
                    width: height

                    onClicked: {
                        search.open()
                    }
                }

                ToolButton {
                    height: Kube.Units.gridUnit * 1.5
                    width: height

                    iconName: Kube.Icons.mail_inverted

                    onClicked: {
                        //TODO
                    }
                }

                ToolButton {
                    height: Kube.Units.gridUnit * 1.5
                    width: height

                    iconName: Kube.Icons.user_inverted

                    onClicked: {
                        people.open()
                    }
                }

                Kube.AccountSwitcher {
                    height: Kube.Units.gridUnit * 1.5
                    width: height
                }
            }
            Column {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: Kube.Units.smallSpacing
                    horizontalCenter: parent.horizontalCenter
                }

                spacing: Kube.Units.largeSpacing - Kube.Units.smallSpacing
                Kube.Outbox {
                    height: Kube.Units.gridUnit * 1.5
                    width: height
                }
            }
        }

        SplitView {
            height: app.height
            Layout.fillWidth: true

            Rectangle {
                width: Kube.Units.gridUnit * 10
                Layout.maximumWidth: app.width * 0.25
                Layout.minimumWidth: Kube.Units.gridUnit * 5

                color: Kube.Colors.textColor

                Kube.PositiveButton {
                    id: newMailButton

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: Kube.Units.largeSpacing
                    }

                    text: qsTr("New Email")

                    onClicked: {
                        composer.open()
                    }
                }

                Kube.InlineAccountSwitcher {
                    id: accountFolderview

                    anchors {
                        top: newMailButton.bottom
                        topMargin: Kube.Units.largeSpacing
                        bottom: parent.bottom
                        left: newMailButton.left
                        right: parent.right
                    }
                    width: parent.width - Kube.Units.largeSpacing
                }
            }
//TODO bring back status bar
//                 Item {
//                     id: statusBar
//                     anchors {
//                         topMargin: Kube.Units.smallSpacing
//                         bottom: outbox.top
//                         left: parent.left
//                         right: parent.right
//                     }
//
//                     height: Kube.Units.gridUnit
//
//                     Repeater {
//                         model: currentAccountModel
//                         Kube.Label {
//                             id: statusText
//                             anchors.centerIn: parent
//                             visible: false
//                             color: Kube.Colors.highlightedTextColor
//                             states: [
//                             State {
//                                 name: "disconnected"; when: model.status == Kube.AccountsModel.OfflineStatus
//                                 PropertyChanges { target: statusText; text: "Offline"; visible: true }
//                             }
//                             ]
//                         }
//                     }
//                 }

            Kube.MailListView  {
                id: mailListView
                parentFolder: accountFolderview.currentFolder
                width: Kube.Units.gridUnit * 20
                height: parent.height
                Layout.maximumWidth: app.width * 0.4
                Layout.minimumWidth: Kube.Units.gridUnit * 10
                focus: true
            }

            Kube.ConversationView {
                id: mailView
                mail: mailListView.currentMail
                Layout.fillWidth: true
                hideTrash: !accountFolderview.isTrashFolder
                hideNonTrash: accountFolderview.isTrashFolder
            }
        }
    }
    //END Main content

    //BEGIN Composer
    Kube.FocusComposer {
        id: composer

        height: app.height * 0.85
        width: app.width * 0.85

        x: app.width * 0.075
        y: app.height * 0.075
    }
    //END Composer

    //BEGIN AccountWizard
    KubeAccounts.AccountWizard {
        id: accountWizard

        height: app.height * 0.85
        width: app.width * 0.85

        x: app.width * 0.075
        y: app.height * 0.075
    }
    //END AccountWizard

    //BEGIN Notification
    Kube.NotificationPopup {
        id: notificationPopup

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
    }
    //END Notification

    //BEGIN Search
    Kube.Popup {
        id: search

        width: app.width * 0.6
        height: Kube.Units.gridUnit * 3

        x: app.width * 0.2
        y: app.height * 0.2

        RowLayout {
            anchors.centerIn: parent
            width: parent.width

            Kube.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Filter...     (only applies to the mail list for now)"
            }

            Kube.Button {
                text: "Go"

                onClicked: {
                    mailListView.filterString = searchField.text
                    search.close()
                }
            }
        }
    }
    //END Search

    //BEGIN People
    Kube.People {
        id: people

        height: app.height * 0.85
        width: app.width * 0.85

        x: app.width * 0.075
        y: app.height * 0.075

    }
    //END People
}

/*
 *  Copyright (C) 2017 Michael Bohlender, <michael.bohlender@kdemail.net>
 *  Copyright (C) 2017 Christian Mollekopf, <mollekopf@kolabsys.com>
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


import QtQuick 2.9
import QtQuick.Controls 1.3 as Controls1
import QtQuick.Controls 2
import QtQuick.Layouts 1.1

import org.kube.framework 1.0 as Kube

Kube.View {
    id: root
    property variant currentFolder: null

    //We have to hardcode because all the mapToItem/mapFromItem functions are garbage
    searchArea: Qt.rect(ApplicationWindow.window.sidebarWidth + mailListView.parent.x, 0, (mailView.x + mailView.width) - mailListView.parent.x, (mailView.y + mailView.height) - mailListView.y)

    onFilterChanged: {
        mailListView.filter = filter
        Kube.Fabric.postMessage(Kube.Messages.searchString, {"searchString": filter})
    }

    onRefresh: {
        if (!!root.currentFolder) {
            Kube.Fabric.postMessage(Kube.Messages.synchronize, {"folder": root.currentFolder});
            Kube.Fabric.postMessage(Kube.Messages.synchronize, {"accountId": Kube.Context.currentAccountId, "type": "folder"})
        } else {
            Kube.Fabric.postMessage(Kube.Messages.synchronize, {"accountId": Kube.Context.currentAccountId})
        }
    }

    Kube.Listener {
        filter: Kube.Messages.search
        onMessageReceived: root.triggerSearch()
    }

    helpViewComponent: Kube.HelpPopup {
        ListModel {
            ListElement { description: qsTr("Jump to next thread:"); shortcut: "j" }
            ListElement { description: qsTr("Jump to previous thread:"); shortcut: "k" }
            ListElement { description: qsTr("Jump to next message:"); shortcut: "n" }
            ListElement { description: qsTr("Jump to previous message:"); shortcut: "p" }
            ListElement { description: qsTr("Jump to next folder:"); shortcut: "f,n" }
            ListElement { description: qsTr("Jump to previous folder:"); shortcut: "f,p" }
            ListElement { description: qsTr("Compose new message:"); shortcut: "c" }
            ListElement { description: qsTr("Reply to the currently focused message:"); shortcut: "r" }
            ListElement { description: qsTr("Delete the currently focused message:"); shortcut: "d" }
            ListElement { description: qsTr("Mark the currently focused message as important:"); shortcut: "i" }
            ListElement { description: qsTr("Mark the currently focused message as unread:"); shortcut: "u" }
            ListElement { description: qsTr("Show this help text:"); shortcut: "?" }
        }
    }

    Shortcut {
        enabled: root.isCurrentView
        sequences: ['j']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectNextConversation, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['k']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectPreviousConversation, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['Shift+J']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.scrollConversationDown, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['Shift+K']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.scrollConversationUp, {})
    }
    Shortcut {
        sequences: ['n']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectNextMessage, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['p']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectPreviousMessage, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['f,n']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectNextFolder, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['f,p']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.selectPreviousFolder, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequences: ['c']
        onActivated: Kube.Fabric.postMessage(Kube.Messages.compose, {})
    }
    Shortcut {
        enabled: root.isCurrentView
        sequence: "?"
        onActivated: root.showHelp()
    }


    Controls1.SplitView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Rectangle {
            width: Kube.Units.gridUnit * 10
            Layout.fillHeight: parent.height
            color: Kube.Colors.darkBackgroundColor

            Kube.PositiveButton {
                id: newMailButton
                objectName: "newMailButton"

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Kube.Units.largeSpacing
                }
                focus: true
                text: qsTr("New Email")
                onClicked: Kube.Fabric.postMessage(Kube.Messages.compose, {})
            }

            Kube.InlineAccountSwitcher {
                id: accountFolderview
                activeFocusOnTab: true
                anchors {
                    top: newMailButton.bottom
                    topMargin: Kube.Units.largeSpacing
                    bottom: statusBarContainer.top
                    left: newMailButton.left
                    right: parent.right
                }
                delegate: Kube.FolderListView {
                    objectName: "folderListView"
                    accountId: parent.accountId

                    function indexSelected(currentIndex) {
                        var folder = model.data(currentIndex, Kube.FolderListModel.DomainObject)
                        Kube.Fabric.postMessage(Kube.Messages.folderSelection, {"folder": folder,
                                                                                "trash": model.data(currentIndex, Kube.FolderListModel.Trash)})
                        root.currentFolder = folder
                    }

                    //Necessary to re-select on account change
                    function currentChanged() {
                        if (isCurrent) {
                            indexSelected(currentIndex)
                        }
                    }

                    onCurrentIndexChanged: {
                        if (isCurrent) {
                            indexSelected(currentIndex)
                        }
                    }
                }
            }

            Item {
                id: statusBarContainer
                anchors {
                    topMargin: Kube.Units.smallSpacing
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: childrenRect.height

                Rectangle {
                    id: border
                    visible: statusBar.visible
                    anchors {
                        right: parent.right
                        left: parent.left
                        margins: Kube.Units.smallSpacing
                    }
                    height: 1
                    color: Kube.Colors.viewBackgroundColor
                    opacity: 0.3
                }
                Kube.StatusBar {
                    id: statusBar
                    accountId: Kube.Context.currentAccountId
                    height: Kube.Units.gridUnit * 2
                    anchors {
                        top: border.bottom
                        left: statusBarContainer.left
                        right: statusBarContainer.right
                    }
                }
            }
        }

        Rectangle {
            width: Kube.Units.gridUnit * 18
            Layout.fillHeight: parent.height

            color: "transparent"
            border.width: 1
            border.color: Kube.Colors.buttonColor

            Kube.MailListView  {
                id: mailListView
                objectName: "mailListView"
                anchors.fill: parent
                activeFocusOnTab: true
                Layout.minimumWidth: Kube.Units.gridUnit * 10
                Kube.Listener {
                    filter: Kube.Messages.folderSelection
                    onMessageReceived: {
                        root.clearSearch()
                        mailListView.parentFolder = message.folder
                    }
                }
                onCurrentMailChanged: {
                    Kube.Fabric.postMessage(Kube.Messages.mailSelection, {"mail": currentMail})
                }
            }
        }

        Kube.ConversationView {
            id: mailView
            objectName: "mailView"
            Layout.fillWidth: true
            Layout.fillHeight: parent.height
            activeFocusOnTab: true
            model: Kube.MailListModel {
                id: mailViewModel
            }
            Kube.Listener {
                filter: Kube.Messages.mailSelection
                onMessageReceived: {
                    if (!mailListView.threaded) {
                        mailViewModel.singleMail = message.mail
                    } else {
                        mailViewModel.mail = message.mail
                    }
                }
            }

            Kube.Listener {
                filter: Kube.Messages.folderSelection
                onMessageReceived: {
                    mailView.hideTrash = !message.trash
                    mailView.hideNonTrash = message.trash
                }
            }

        }
    }

}

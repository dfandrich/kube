/*
 *  Copyright (C) 2017 Michael Bohlender, <bohlender@kolabsys.com>
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

import QtQuick 2.7
import QtQuick.Controls 2.2
import org.kube.framework 1.0 as Kube
import QtQuick.Layouts 1.3

QtObject {
    id: root
    property string text: null
    property var layout: null
    property var visualParent: layout.parent
    onVisualParentChanged: {
        component.createObject(visualParent)
    }

    property var comp: Component {
        id: component
        Item {
            anchors.fill: layout

            /**
             * This assumes a layout filled with labels.
             * We iterate over all elements, extract the text, insert a linebreak after every line and a space otherwise.
             */
            function gatherText() {
                var gatheredText = "";
                var length = layout.visibleChildren.length
                for (var i = 0; i < length; i++) {
                    var item = layout.visibleChildren[i]

                    if (item && item.text) {
                        gatheredText += item.text;
                    }
                    if (layout.columns && (((i + 1) % layout.columns) == 0)) {
                        gatheredText += "\n";
                    } else if (i != length - 1){
                        gatheredText += " ";
                    }
                }
                // console.warn("Gathered text: ", gatheredText)
                return gatheredText
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Kube.Colors.highlightColor
                border.width: 1
                visible: mouseArea.containsMouse || menu.visible
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.RightButton
                z: 1
                onClicked: {
                    menu.x = mouseX
                    menu.y = mouseY
                    menu.open()
                    mouse.accepted = true
                }
            }
            Menu {
                id: menu

                height: menuLayout.height
                width: menuLayout.width
                background: Rectangle {
                    anchors.fill: parent
                    color: Kube.Colors.backgroundColor
                }
                RowLayout {
                    id: menuLayout
                    width: button.width
                    height: button.height
                    Kube.TextButton {
                        id: button
                        text: "Copy"
                        onClicked: {
                            if (root.text) {
                                clipboard.text = root.text
                            } else {
                                clipboard.text = gatherText()
                            }
                            menu.close()
                        }
                    }
                }
                Kube.Clipboard {
                    id: clipboard
                }
            }
        }
    }
}

/*
    Copyright 2011-2012 Heikki Holstila <heikki.holstila@gmail.com>

    This file is part of FingerTerm.

    FingerTerm is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    FingerTerm is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with FingerTerm.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0

Item {
    id: menuWin
    property bool enableCopy: false
    property bool enablePaste: false
    property string currentSwipeLocking: util.settingsValue("ui/allowSwipe")
    property string currentShowMethod: util.settingsValue("ui/vkbShowMethod")
    property string currentDragMode: util.settingsValue("ui/dragMode")
    property string currentOrientationLockMode: util.settingsValue("ui/orientationLockMode")
    property int keyboardFadeOutDelay: util.settingsValue("ui/keyboardFadeOutDelay")

    Item {
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: flickableContent.width

        XmlListModel {
            id: xmlModel
            xml: term.getUserMenuXml()
            query: "/userMenu/item"

            XmlRole { name: "title"; query: "title/string()" }
            XmlRole { name: "command"; query: "command/string()" }
            XmlRole { name: "disableOn"; query: "disableOn/string()" }
        }

        Component {
            id: xmlDelegate
            BackgroundItem {
                width: menuWin.width
                enabled: disableOn.length === 0 || window.windowTitle.search(disableOn) === -1
                Label {
                    text: title
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                    }
                }
                onClicked: {
                    hideMenu();
                    term.putString(command, true);
                }
            }
        }

        SilicaFlickable {
            id: menuFlickArea
            anchors.fill: parent
            contentHeight: flickableContent.height

            PullDownMenu {
                MenuItem {
                    text: "About"
                    onClicked: {
                        hideMenu();
                        aboutDialog.termW = term.termSize().width
                        aboutDialog.termH = term.termSize().height
                        aboutDialog.state = "visible"
                    }
                }
                MenuItem {
                    text: "Keyboard layout"
                    onClicked: {
                        hideMenu();
                        layoutWindow.layouts = keyLoader.availableLayouts();
                        layoutWindow.state = "visible";
                    }
                }
                MenuItem {
                    text: "URL grabber"
                    onClicked: {
                        hideMenu();
                        urlWindow.urls = term.grabURLsFromBuffer();
                        urlWindow.state = "visible";
                    }
                }
                MenuItem {
                    text: "New window"
                    onClicked: {
                        hideMenu();
                        util.openNewWindow();
                    }
                }
            }

            VerticalScrollDecorator { flickable: menuFlickArea }

            Column {
                id: flickableContent
                width: menuWin.width
                spacing: 12

                Row {
                    id: menuBlocksRow
                    width: menuWin.width
                    spacing: 8

                    Column {
                        spacing: 12
                        width: menuWin.width

                        PageHeader {
                            title: 'Shortcuts'
                        }

                        Repeater {
                            model: xmlModel
                            delegate: xmlDelegate
                        }

                        PageHeader {
                            title: 'Clipboard'
                        }

                        Row {
                            Button {
                                text: "Copy"
                                onClicked: {
                                    hideMenu();
                                    term.copySelectionToClipboard();
                                }
                                enabled: menuWin.enableCopy
                            }
                            Button {
                                text: "Paste"
                                onClicked: {
                                    hideMenu();
                                    term.pasteFromClipboard();
                                }
                                enabled: menuWin.enablePaste
                            }
                        }

                        PageHeader {
                            title: 'Settings'
                        }

                        ComboBox {
                            label: 'Font size'
                            menu: ContextMenu {
                                MenuItem {
                                    text: 'Increase'
                                    onClicked: {
                                        textrender.fontPointSize = textrender.fontPointSize + 1;
                                        lineView.fontPointSize = textrender.fontPointSize;
                                        util.notifyText(term.termSize().width+"x"+term.termSize().height);
                                    }
                                }

                                MenuItem {
                                    text: 'Decrease'
                                    onClicked: {
                                        textrender.fontPointSize = textrender.fontPointSize - 1;
                                        lineView.fontPointSize = textrender.fontPointSize;
                                        util.notifyText(term.termSize().width+"x"+term.termSize().height);
                                    }
                                }
                            }
                        }

                        ComboBox {
                            label: 'UI Orientation'
                            // TODO: Set selection on load (from currentOrientationLockMode)
                            menu: ContextMenu {
                                MenuItem {
                                    text: 'Auto'
                                    onClicked: {
                                        currentOrientationLockMode = "auto";
                                        window.setOrientationLockMode("auto");
                                    }
                                }
                                MenuItem {
                                    text: 'Landscape'
                                    onClicked: {
                                        currentOrientationLockMode = "landscape";
                                        window.setOrientationLockMode("landscape");
                                    }
                                }
                                MenuItem {
                                    text: 'Portrait'
                                    onClicked: {
                                        currentOrientationLockMode = "portrait";
                                        window.setOrientationLockMode("portrait");
                                    }
                                }
                            }
                        }

                        ComboBox {
                            label: 'Drag mode'
                            // TODO: Set selection on load (from currentDragMode)
                            menu: ContextMenu {
                                MenuItem {
                                    text: 'Gesture'
                                    onClicked: {
                                        util.setSettingsValue("ui/dragMode", "gestures");
                                        term.clearSelection();
                                        currentDragMode = "gestures";
                                        hideMenu();
                                    }
                                }
                                MenuItem {
                                    text: 'Scroll'
                                    onClicked: {
                                        util.setSettingsValue("ui/dragMode", "scroll");
                                        currentDragMode = "scroll";
                                        term.clearSelection();
                                        hideMenu();
                                    }
                                }
                                MenuItem {
                                    text: 'Select'
                                    onClicked: {
                                        util.setSettingsValue("ui/dragMode", "select");
                                        currentDragMode = "select";
                                        hideMenu();
                                    }
                                }
                            }
                        }

                        ComboBox {
                            label: 'VKB behavior'
                            // TODO: Set selection on load (from currentShowMethod)
                            menu: ContextMenu {
                                MenuItem {
                                    text: 'Off'
                                    onClicked: {
                                        util.setSettingsValue("ui/vkbShowMethod", "off");
                                        currentShowMethod = "off";
                                        window.setTextRenderAttributes();
                                        hideMenu();
                                    }
                                }
                                MenuItem {
                                    text: 'Fade'
                                    onClicked: {
                                            util.setSettingsValue("ui/vkbShowMethod", "fade");
                                            currentShowMethod = "fade";
                                            window.setTextRenderAttributes();
                                            hideMenu();
                                    }
                                }
                                MenuItem {
                                    text: 'Move'
                                    onClicked: {
                                            util.setSettingsValue("ui/vkbShowMethod", "move");
                                            currentShowMethod = "move";
                                            window.setTextRenderAttributes();
                                            hideMenu();
                                    }
                                }
                            }
                        }

                    }
                }
                // VKB delay slider
                Rectangle {
                    id: vkbDelaySliderArea
                    width: menuBlocksRow.width
                    height: 68
                    radius: 5
                    color: "#606060"
                    border.color: "#000000"
                    border.width: 1
                    Text {
                        width: parent.width
                        height: 20
                        color: "#ffffff"
                        font.pointSize: util.uiFontSize()-1;
                        text: "VKB delay: " + vkbDelaySlider.keyboardFadeOutDelayLabel + " ms"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle {
                        x: 5
                        y: vkbDelaySlider.y + vkbDelaySlider.height/2 - height/2
                        width: menuBlocksRow.width - 10
                        height: 10
                        radius: 5
                        z: 1
                        color: "#909090"
                    }
                    Rectangle {
                        id: vkbDelaySlider
                        property int keyboardFadeOutDelayLabel: keyboardFadeOutDelay
                        x: (keyboardFadeOutDelay-1000)/9000 * (vkbDelaySliderArea.width - vkbDelaySlider.width)
                        y: 20
                        width: 60
                        radius: 15
                        height: parent.height-20
                        color: "#202020"
                        z: 2
                        onXChanged: {
                            if (vkbDelaySliderMA.drag.active)
                                vkbDelaySlider.keyboardFadeOutDelayLabel =
                                        Math.floor((1000+vkbDelaySlider.x/vkbDelaySliderMA.drag.maximumX*9000)/250)*250;
                        }
                        MouseArea {
                            id: vkbDelaySliderMA
                            anchors.fill: parent
                            drag.target: vkbDelaySlider
                            drag.axis: Drag.XAxis
                            drag.minimumX: 0
                            drag.maximumX: vkbDelaySliderArea.width - vkbDelaySlider.width
                            drag.onActiveChanged: {
                                if (!drag.active) {
                                    keyboardFadeOutDelay = vkbDelaySlider.keyboardFadeOutDelayLabel
                                    util.setSettingsValue("ui/keyboardFadeOutDelay", keyboardFadeOutDelay);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: util
        onClipboardOrSelectionChanged: {
            enableCopy = util.terminalHasSelection();
            enablePaste = util.canPaste();
        }
    }

    function showMenu()
    {
        enableCopy = util.terminalHasSelection();
        enablePaste = util.canPaste();
    }

    function hideMenu()
    {
        pageStack.pop();
    }

    function changeSwipeLocking(state)
    {
        currentSwipeLocking = state
        util.setSettingsValue("ui/allowSwipe", state)
        util.updateSwipeLock(!vkb.active);
    }
}

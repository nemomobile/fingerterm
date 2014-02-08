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
                enabled: disableOn.length === 0 || appWindow.windowTitle.search(disableOn) === -1
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
                        pageStack.push('AboutPage.qml')
                    }
                }
                MenuItem {
                    text: "Keyboard layout"
                    onClicked: {
                        pageStack.push('LayoutPage.qml')
                    }
                }
                MenuItem {
                    text: "URL grabber"
                    onClicked: {
                        pageStack.push('UrlGrabberPage.qml')
                    }
                }
                /* Disabled, as QProcess::startDetached() hangs the process
                MenuItem {
                    text: "New window"
                    onClicked: {
                        hideMenu();
                        util.openNewWindow();
                    }
                }
                */
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
                            anchors.horizontalCenter: parent.horizontalCenter
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

                        Slider {
                            id: fontSizeSlider
                            width: parent.width

                            label: 'Font size'
                            valueText: '' + Math.floor(value) + ' pt'

                            value: util.settingsValue("ui/fontSize")
                            minimumValue: 8
                            maximumValue: 80

                            onValueChanged: {
                                textrender.fontPointSize = Math.floor(value);
                                lineView.fontPointSize = textrender.fontPointSize;
                                util.notifyText(term.termSize().width+"x"+term.termSize().height);
                            }
                        }

                        /*
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

                        Slider {
                            id: vkbDelaySlider
                            width: parent.width

                            label: 'VKB fade-out delay'
                            valueText: '' + Math.floor(value) + ' ms'

                            value: menuWin.keyboardFadeOutDelay
                            minimumValue: 1000
                            maximumValue: 10000
                            stepSize: 250

                            onValueChanged: {
                                menuWin.keyboardFadeOutDelay = value;
                                util.setSettingsValue("ui/keyboardFadeOutDelay", value);
                            }
                        }
                        */
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

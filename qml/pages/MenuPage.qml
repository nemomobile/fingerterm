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
import Sailfish.Silica 1.0

Page {
    id: menuWin
    property bool enableCopy: false
    property bool enablePaste: false
    property string currentDragMode: util.settingsValue("ui/dragMode")
    property int keyboardFadeOutDelay: util.settingsValue("ui/keyboardFadeOutDelay")

    Item {
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: flickableContent.width

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
                                util.notifyText(term.termSize().width+"x"+term.termSize().height);
                            }
                        }

                        /*
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
}

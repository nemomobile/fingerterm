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

Rectangle {
    id: key
    property string label: ""
    property string label_alt: ""
    property int code: 0
    property int code_alt: 0
    property int currentCode: (shiftActive && label_alt != '') ? code_alt : code
    property string currentLabel: (shiftActive && label_alt != '') ? label_alt : label
    property bool sticky: false     // can key be stickied?
    property bool becomesSticky: false // will this become sticky after release?
    property int stickiness: 0      // current stickiness status
    property real labelOpacity: keyboard.active ? 1.0 : 0.3

    // mouse input handling
    property int clickThreshold: 20
    property bool isClick: false
    property int pressMouseY: 0
    property int pressMouseX: 0

    width: window.width/12   // some default
    height: Theme.itemSizeSmall

    color: (keyboard.currentKeyPressed === key) ? Theme.secondaryHighlightColor : 'transparent'

    property bool shiftActive: (keyboard.keyModifiers & Qt.ShiftModifier) && !sticky

    Image {
        anchors.right: parent.right
        // FIXME: Don't hardcode the full path here
        source: '/usr/share/maliit/plugins/com/jolla/graphic-keyboard-highlight-top.png'
    }

    Image {
        id: keyIcon
        anchors.centerIn: parent

        property var images: (['backspace', 'down', 'enter', 'left', 'right', 'shift', 'tab', 'up'])
        source: (images.indexOf(key.label) !== -1) ? ('icons/' + key.label + '.png') : ''
    }

    Label {
        id: keyLabel
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeSmall

        // FIXME: Once we have a font that has nice glyphs for these, get rid if the image above
        property var icons: ({tab: '↹', up: '↑', down: '↓', left: '←', right: '→'})
        text: {
            if (keyIcon.images.indexOf(key.label) === -1 && key.label.length > 0) {
                return key.label.charAt(0).toUpperCase() + key.label.substr(1)
            } else {
                return ''
            }
        }
    }

    Rectangle {
        id: stickIndicator
        visible: sticky && stickiness>0
        color: Theme.primaryColor
        anchors.fill: parent
        opacity: 0.5
        z: 1
        anchors.topMargin: key.height/2
    }

    function handlePress(touchArea, x, y) {
        isClick = true;
        pressMouseX = x;
        pressMouseY = y;

        keyboard.currentKeyPressed = key;
        //util.keyPressFeedback();

        keyRepeatStarter.start();

        if (sticky) {
            keyboard.keyModifiers |= code;
            key.becomesSticky = true;
            keyboard.currentStickyPressed = key;
        } else {
            keyboard.nonStickyKeyPressed();
        }
    }

    function handleMove(touchArea, x, y) {
        var mappedPoint = key.mapFromItem(touchArea, x, y)
        if (!key.contains(Qt.point(mappedPoint.x, mappedPoint.y))) {
            key.handleRelease(touchArea, x, y);
            return false;
        }

        if (key.isClick) {
            if (Math.abs(x - key.pressMouseX) > key.clickThreshold ||
            Math.abs(y - key.pressMouseY) > key.clickThreshold )
            key.isClick = false
        }

        return true;
    }

    function handleRelease(touchArea, x, y) {
        keyRepeatStarter.stop();
        keyRepeatTimer.stop();
        keyboard.currentKeyPressed = 0;

        if (sticky && !becomesSticky) {
            keyboard.keyModifiers &= ~code
            keyboard.currentStickyPressed = null;
        }

        if (vkb.keyAt(x, y) == key) {
            //util.keyReleaseFeedback();

            if (key.sticky && key.becomesSticky) {
                setStickiness(-1);
            }

            window.vkbKeypress(currentCode, keyboard.keyModifiers);

            // first non-sticky press will cause the sticky to be released
            if( !sticky && keyboard.resetSticky != 0 && keyboard.resetSticky !== key ) {
                resetSticky.setStickiness(0);
            }
        }
    }

    Timer {
        id: keyRepeatStarter
        running: false
        repeat: false
        interval: 400
        triggeredOnStart: false
        onTriggered: {
            keyRepeatTimer.start();
        }
    }

    Timer {
        id: keyRepeatTimer
        running: false
        repeat: true
        triggeredOnStart: true
        interval: 80
        onTriggered: {
            window.vkbKeypress(currentCode, keyboard.keyModifiers);
        }
    }

    function setStickiness(val)
    {
        if(sticky) {
            if( keyboard.resetSticky != 0 && keyboard.resetSticky !== key ) {
                resetSticky.setStickiness(0)
            }

            if(val===-1)
                stickiness = (stickiness+1) % 3
            else
                stickiness = val

            // stickiness == 0 -> not pressed
            // stickiness == 1 -> release after next keypress
            // stickiness == 2 -> keep pressed

            if(stickiness>0) {
                keyboard.keyModifiers |= code
            } else {
                keyboard.keyModifiers &= ~code
            }

            keyboard.resetSticky = 0

            if(stickiness==1) {
                stickIndicator.anchors.topMargin = key.height/2
                keyboard.resetSticky = key
            } else if(stickiness==2) {
                stickIndicator.anchors.topMargin = 0
            }
        }
    }
}

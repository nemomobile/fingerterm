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
import TextRender 1.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: appWindow
    property string windowTitle: util.currentWindowTitle()
    property variant lines: []

    Keys.onPressed: {
        window.vkbKeypress(event.key, event.modifiers);
    }

    cover: Qt.resolvedUrl("Cover.qml")

    initialPage: Page {
        id: page

        //orientationLock: window.getOrientationLockMode()
        allowedOrientations: Orientation.All

        Rectangle {
        property string fgcolor: "black"
        property string bgcolor: "#88000000"
        property int fontSize: 14

        property int fadeOutTime: 80
        property int fadeInTime: 350


        anchors.fill: parent

        id: window
        objectName: "window"
        color: bgcolor

        Keyboard {
            id: vkb
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            visible: Qt.inputMethod.visible

            function resetStickyByInputMethod() {
                if (vkb.resetSticky != 0) {
                    vkb.resetSticky.setStickiness(0);
                }
            }
        }

        // area that handles gestures/select/scroll modes and vkb-keypresses
        MultiPointTouchArea {
            id: multiTouchArea
            anchors.fill: parent

            property int firstTouchId: -1
            property var pressedKeys: ({})

            Timer {
                id: showInputMethodTimer
                interval: 100

                function queue() {
                    if (!Qt.inputMethod.visible) {
                        dummyTextField.focus = false;
                        start();
                    }
                }

                onTriggered: {
                    dummyTextField.focus = true;
                    Qt.inputMethod.show();
                }
            }

            onPressed: {
                touchPoints.forEach(function (touchPoint) {
                    if (multiTouchArea.firstTouchId == -1) {
                        multiTouchArea.firstTouchId = touchPoint.pointId;

                        //gestures c++ handler
                        util.mousePress(touchPoint.x, touchPoint.y);

                        // Always show input when touching first
                        showInputMethodTimer.queue();
                    }

                    var key = vkb.keyAt(touchPoint.x, touchPoint.y);
                    if (key != null) {
                        key.handlePress(multiTouchArea, touchPoint.x, touchPoint.y);
                    }
                    multiTouchArea.pressedKeys[touchPoint.pointId] = key;
                });
            }
            onUpdated: {
                touchPoints.forEach(function (touchPoint) {
                    if (multiTouchArea.firstTouchId == touchPoint.pointId) {
                        //gestures c++ handler
                        util.mouseMove(touchPoint.x, touchPoint.y);
                    }

                    var key = multiTouchArea.pressedKeys[touchPoint.pointId];
                    if (key != null) {
                        if (!key.handleMove(multiTouchArea, touchPoint.x, touchPoint.y)) {
                            delete multiTouchArea.pressedKeys[touchPoint.pointId];
                        }
                    }
                });
            }
            onReleased: {
                touchPoints.forEach(function (touchPoint) {
                    if (multiTouchArea.firstTouchId == touchPoint.pointId) {
                        //gestures c++ handler
                        util.mouseRelease(touchPoint.x, touchPoint.y);
                        multiTouchArea.firstTouchId = -1;
                    }

                    var key = multiTouchArea.pressedKeys[touchPoint.pointId];
                    if (key != null) {
                        key.handleRelease(multiTouchArea, touchPoint.x, touchPoint.y);
                    }
                    delete multiTouchArea.pressedKeys[touchPoint.pointId];
                });
            }
            onCanceled: {
                touchPoints.forEach(function (touchPoint) {
                    if (multiTouchArea.firstTouchId == touchPoint.pointId) {
                        multiTouchArea.firstTouchId = -1;
                    }
                    delete multiTouchArea.pressedKeys[touchPoint.pointId];
                });
            }
        }

        Image {
            // terminal buffer scroll indicator
            source: "icons/scroll-indicator.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            visible: textrender.showBufferScrollIndicator
            z: 5
        }

        TextRender {
            id: textrender
            objectName: "textrender"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: vkb.visible ? vkb.top : parent.bottom
            }

            myWidth: width
            myHeight: height
            opacity: 1.0
            property int duration: 0;
            property int cutAfter: height

            Behavior on opacity {
                NumberAnimation { duration: textrender.duration; easing.type: Easing.InOutQuad }
            }
            Behavior on y {
                NumberAnimation { duration: textrender.duration; easing.type: Easing.InOutQuad }
            }

            onCutAfterChanged: {
                // this property is used in the paint function, so make sure that the element gets
                // painted with the updated value (might not otherwise happen because of caching)
                textrender.redraw();
            }

            z: 10
        }

        Timer {
            id: bellTimer
            running: false
            repeat: false
            interval: 80
            onTriggered: {
                window.color = window.bgcolor;
            }
        }

        Connections {
            target: util
            onVisualBell: {
                window.visualBell();
            }
            onGestureNotify: {
                textNotify.text = msg;
                textNotifyAnim.enabled = false;
                textNotify.opacity = 1.0;
                textNotifyAnim.enabled = true;
                textNotify.opacity = 0;
            }
            onWindowTitleChanged: {
                appWindow.windowTitle = util.currentWindowTitle()
            }
        }

        Text {
            // shows large text notification in the middle of the screen (for gestures)
            id: textNotify
            anchors.centerIn: parent
            color: "#ffffff"
            z: 100
            opacity: 0
            text: ""
            font.pointSize: 40
            Behavior on opacity {
                id: textNotifyAnim
                NumberAnimation { duration: 500; }
            }
        }

        Rectangle {
            // visual key press feedback...
            // easier to work with the coordinates if it's here and not under keyboard element
            id: visualKeyFeedbackRect
            visible: false
            x: 0
            y: 0
            z: 200
            width: 0
            height: 0
            radius: 5
            color: Theme.highlightColor
            property string label: ""
            Text {
                color: Theme.primaryColor
                font.pointSize: 34
                anchors.centerIn: parent
                text: visualKeyFeedbackRect.label
            }
        }

        TextInput {
            id: dummyTextField

            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            width: 30
            height: 30
            y: -height
            focus: true

            onTextChanged: {
                var i, ch, mod;

                if (text !== '') {
                    for (i=0; i<text.length; i++) {
                        ch = text[i];
                        mod = (ch === ch.toUpperCase()) ? 0x2000000 : 0;
                        term.keyPress(ch.toLowerCase().charCodeAt(i), mod | vkb.keyModifiers);
                    }

                    text = '';
                    focus = true;
                    vkb.resetStickyByInputMethod();
                }
            }

            Keys.onPressed: {
                event.accepted = true
            }

            Keys.onReleased: {
                term.keyPress(event.key,event.modifiers | vkb.keyModifiers);
                //vkb.resetStickyByInputMethod();
                event.accepted = true
            }
        }

        function vkbKeypress(key,modifiers) {
            wakeVKB();
            term.keyPress(key,modifiers);
        }

        function wakeVKB()
        {
            textrender.duration = window.fadeOutTime;
            util.updateSwipeLock(!vkb.active);
            setTextRenderAttributes();
            updateGesturesAllowed();
        }

        function sleepVKB()
        {
            textrender.duration = window.fadeInTime;
            util.updateSwipeLock(!vkb.active);
            setTextRenderAttributes();
            updateGesturesAllowed();
        }

        function setTextRenderAttributes()
        {
            textrender.opacity = 1.0;
            textrender.cutAfter = textrender.height;
            textrender.y = 0;
        }

        function displayBufferChanged()
        {
            appWindow.lines = term.printableLinesFromCursor(30);
            setTextRenderAttributes();
        }

        Component.onCompleted: {
            util.updateSwipeLock(vkb.active)
        }

        function showErrorMessage(message)
        {
            pageStack.push('MessagePage.qml', {'message': message})
        }

        function visualBell()
        {
            bellTimer.start();
            window.color = "#ffffff"
        }

        function updateGesturesAllowed()
        {
            util.allowGestures = !vkb.active;
        }

        /*
        function lockModeStringToQtEnum(stringMode) {
            switch (stringMode) {
            case "auto":
                return PageOrientation.Automatic
            case "landscape":
                return PageOrientation.LockLandscape
            case "portrait":
                return PageOrientation.LockPortrait
            }
        }

        function getOrientationLockMode()
        {
            var stringMode = util.settingsValue("ui/orientationLockMode");
            page.orientationLock = lockModeStringToQtEnum(stringMode)
        }

        function setOrientationLockMode(stringMode)
        {
            util.setSettingsValue("ui/orientationLockMode", stringMode);
            page.orientationLock = lockModeStringToQtEnum(stringMode)
        }
        */
    }
    }

    Page {
        id: menuPage

        MenuFingerterm {
            id: menu
            anchors.fill: parent
        }
    }

    Component.onCompleted: {
        pageStack.pushAttached(menuPage)
    }
}

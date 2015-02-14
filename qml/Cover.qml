
import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Label {
        id: title

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.paddingSmall
        }

        font {
            pixelSize: Theme.fontSizeSmall
        }

        color: Theme.highlightColor
        text: appWindow.windowTitle

    }

    Label {
        anchors {
            top: (title.text != '') ? title.bottom : parent.top
            left: parent.left
            bottom: parent.bottom
            margins: Theme.paddingSmall
        }

        font {
            family: util.fontFamily
            pixelSize: Theme.fontSizeTiny / 2
        }

        color: Theme.secondaryColor

        text: {
            var res = ''
            for (var i=0; i<appWindow.lines.length; i++) {
                res = res + appWindow.lines[i] + '\n'
            }
            return res.trim()
        }
    }
}

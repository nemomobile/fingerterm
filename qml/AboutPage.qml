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
    Column {
        anchors.fill: parent

        PageHeader {
            title: 'About Terminal'
        }

        Column {
            spacing: Theme.paddingMedium

            anchors {
                margins: Theme.paddingMedium
                left: parent.left
                right: parent.right
            }

            Label {
                text: 'Terminal ' + util.versionString()
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
            }

            Label {
                text: 'based on FingerTerm\nby Heikki Holstila'
            }

            Label {
                text: 'Config files:\n' + util.configPath()
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                text: 'Documentation:\nhttp://hqh.unlink.org/harmattan'
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                text: 'Github project:\nhttp://github.com/nemomobile/fingerterm'
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}

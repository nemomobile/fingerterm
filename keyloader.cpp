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

#include <QtCore>
#include <QDebug>

#include <sailfishapp.h>

#include "keyloader.h"
#include "util.h"

struct KeyDef {
    const char *label;
    int code;
    bool modifier;
};

static const KeyDef KEYCODES[] = {
    // http://doc.qt.io/qt-5/qt.html#KeyboardModifier-enum
    { "shift", Qt::ShiftModifier, true },
    { "ctrl", Qt::ControlModifier, true },
    { "alt", Qt::AltModifier, true },
    { "meta", Qt::MetaModifier, true },

    // http://doc.qt.io/qt-5/qt.html#Key-enum
    { "esc", Qt::Key_Escape, false },
    { "tab", Qt::Key_Tab, false },
    { "backspace", Qt::Key_Backspace, false },
    { "home", Qt::Key_Home, false },
    { "end", Qt::Key_End, false },
    { "left", Qt::Key_Left, false },
    { "up", Qt::Key_Up, false },
    { "right", Qt::Key_Right, false },
    { "down", Qt::Key_Down, false },
    { "pgup", Qt::Key_PageUp, false },
    { "pgdn", Qt::Key_PageDown, false },
};

static const char *DEFAULT_KEY_LAYOUT[2][8] = {
    { "esc",   "tab",  "<|>", "[|]", "\"|_", "up",   "$|%",   "pgup|home" },
    { "shift", "ctrl", "alt", "||~", "left", "down", "right", "pgdn|end" },
};

static KeyData parseKey(const QString &label)
{
    QString primary, secondary;

    switch (label.count('|')) {
        case 0:
            primary = label;
            break;
        case 1:
            primary = label.mid(0, label.indexOf('|'));
            secondary = label.mid(label.indexOf('|') + 1, -1);
            break;
        case 2:
            if (label.startsWith('|')) {
                primary = "|";
                secondary = label.right(label.size() - 2);
            } else if (label.endsWith('|')) {
                primary = label.left(label.size() - 2);
                secondary = "|";
            } else {
                qWarning() << "Invalid key definition:" << label;
                return KeyData();
            }
            break;
        default:
            qWarning() << "Invalid key definition:" << label;
            return KeyData();
            break;
    }

    KeyData key;

    key.label = primary;
    for (const KeyDef &def: KEYCODES) {
        if (key.label == def.label) {
            key.code = def.code;
            key.isModifier = def.modifier;
            break;
        }
    }
    if (!key.code && key.label.size() == 1) {
        key.code = key.label.at(0).unicode();
    }

    key.label_alt = secondary;
    for (const KeyDef &def: KEYCODES) {
        if (key.label_alt == def.label) {
            key.code_alt = def.code;
        }
    }
    if (!key.code_alt && key.label_alt.size() == 1) {
        key.code_alt = key.label_alt.at(0).unicode();
    }

    return key;
}


KeyLoader::KeyLoader(Util *util, QObject *parent)
    : QObject(parent)
    , iVkbRows(0)
    , iVkbColumns(0)
    , iUtil(util)
{
}

KeyLoader::~KeyLoader()
{
}

bool KeyLoader::loadLayout(QString layout)
{
    if(layout.isEmpty() || !iUtil)
        return false;

    QString filename = SailfishApp::pathTo("data/" + layout + ".toolbar").toLocalFile();

    if (!QFile(filename).exists()) {
        filename = iUtil->configPath() + "/" + layout + ".toolbar";
    }

    QFile f(filename);
    return loadLayoutInternal(f);
}

bool KeyLoader::loadLayoutInternal(QIODevice &from)
{
    iKeyData.clear();
    bool ret = true;

    iVkbRows = 0;
    iVkbColumns = 0;

    if( !from.open(QIODevice::ReadOnly | QIODevice::Text) )
        return false;

    while(!from.atEnd()) {
        QString line = QString::fromUtf8(from.readLine()).simplified();

        if (line.length() >= 1 && line.at(0) == '#') {
            // Skip comments
            continue;
        }

        QList<KeyData> keyRow;
        for (const QString &label: line.split(' ')) {
            keyRow.append(parseKey(label));
        }
        iKeyData.append(keyRow);
    }

    for (const QList<KeyData> &r: iKeyData) {
        iVkbColumns = qMax(r.count(), iVkbColumns);
    }
    iVkbRows = iKeyData.count();

    from.close();

    if (iVkbColumns <= 0 || iVkbRows <= 0) {
        ret = false;
    }

    if (!ret) {
        iKeyData.clear();
    }

    return ret;
}

bool KeyLoader::loadDefaultLayout()
{
    iKeyData.clear();
    for (auto &row: DEFAULT_KEY_LAYOUT) {
        QList<KeyData> keyRow;
        for (auto &label: row) {
            keyRow.append(parseKey(label));
        }
        iKeyData.append(keyRow);
    }

    return true;
}

QVariantList KeyLoader::keyAt(int row, int col)
{
    KeyData k;

    if(iKeyData.count() > row && iKeyData.at(row).count() > col) {
        k = iKeyData.at(row).at(col);
    }

    return QVariantList() << k.label << k.code << k.label_alt << k.code_alt << k.width << k.isModifier;
}

QStringList KeyLoader::availableLayouts()
{
    QStringList filter("*.toolbar");

    QStringList searchPaths;
    searchPaths << SailfishApp::pathTo("data").toLocalFile();
    searchPaths << iUtil->configPath();

    QStringList result;
    for (const QString &searchPath: searchPaths) {
        foreach(QString s, QDir(searchPath).entryList(filter, QDir::Files|QDir::Readable, QDir::Name)) {
            result << s.left(s.lastIndexOf('.'));
        }
    }
    return result;
}

void KeyLoader::dump()
{
    for (auto &row: iKeyData) {
        qDebug() << "======== ROW ========";
        for (auto &key: row) {
            qDebug() << "Key:" << key.label << key.code <<
                        "Alt:" << key.label_alt << key.code_alt <<
                        "Attr:" << key.width << key.isModifier;
        }
        qDebug() << "======== ROW ========";
    }
}

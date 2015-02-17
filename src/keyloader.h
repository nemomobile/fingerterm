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

#ifndef KEYLOADER_H
#define KEYLOADER_H

#include <QtCore>

class Util;

struct KeyData {
    KeyData()
        : label()
        , code(0)
        , label_alt()
        , code_alt(0)
        , width(1)
        , isModifier(false)
    {
    }

    QString label;
    int code;
    QString label_alt;
    int code_alt;
    int width;
    bool isModifier;
};

class KeyLoader : public QObject
{
    Q_OBJECT
public:
    explicit KeyLoader(Util *util, QObject *parent = 0);
    virtual ~KeyLoader();

    Q_INVOKABLE bool loadLayout(QString layout);
    Q_INVOKABLE bool loadDefaultLayout();

    Q_INVOKABLE int vkbRows() { return iVkbRows; }
    Q_INVOKABLE int vkbColumns() { return iVkbColumns; }
    Q_INVOKABLE QVariantList keyAt(int row, int col);
    Q_INVOKABLE QStringList availableLayouts();

    Q_INVOKABLE void dump();

signals:

public slots:

private:
    Q_DISABLE_COPY(KeyLoader)
    bool loadLayoutInternal(QIODevice &from);

    int iVkbRows;
    int iVkbColumns;

    QList<QList<KeyData> > iKeyData;

    Util *iUtil;
};

#endif // KEYLOADER_H

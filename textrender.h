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

#ifndef TEXTRENDER_H
#define TEXTRENDER_H

#include <QQuickPaintedItem>
#include <QPainter>

#include "terminal.h"

class Util;

class TextRender : public QQuickPaintedItem
{
    Q_PROPERTY(int myWidth READ myWidth WRITE setMyWidth NOTIFY myWidthChanged)
    Q_PROPERTY(int myHeight READ myHeight WRITE setMyHeight NOTIFY myHeightChanged)
    Q_PROPERTY(int fontWidth READ fontWidth NOTIFY fontSizeChanged)
    Q_PROPERTY(int fontHeight READ fontHeight NOTIFY fontSizeChanged)
    Q_PROPERTY(int fontPointSize READ fontPointSize WRITE setFontPointSize NOTIFY fontSizeChanged)
    Q_PROPERTY(bool showBufferScrollIndicator READ showBufferScrollIndicator WRITE setShowBufferScrollIndicator NOTIFY showBufferScrollIndicatorChanged)

    Q_OBJECT
public:
    explicit TextRender(QQuickItem *parent = 0);
    virtual ~TextRender();
    void paint(QPainter*);

    void setTerminal(Terminal* term);
    void setUtil(Util* util) { iUtil = util; }

    int myWidth() { return iWidth; }
    int myHeight() { return iHeight; }
    void setMyWidth(int w) { if(iWidth!=w) { iWidth=w; emit myWidthChanged(w); } }
    void setMyHeight(int h) { if(iHeight!=h) { iHeight=h; emit myHeightChanged(h); } }
    int fontWidth() { return iFontWidth; }
    int fontHeight() { return iFontHeight; }
    int fontDescent() { return iFontDescent; }
    int fontPointSize() { return iFont.pointSize(); }
    void setFontPointSize(int psize);
    bool showBufferScrollIndicator() { return iShowBufferScrollIndicator; }
    void setShowBufferScrollIndicator(bool s) { if(iShowBufferScrollIndicator!=s) { iShowBufferScrollIndicator=s; emit showBufferScrollIndicatorChanged(); } }

    Q_INVOKABLE QPoint cursorPixelPos();
    Q_INVOKABLE QSize cursorPixelSize();

signals:
    void myWidthChanged(int newWidth);
    void myHeightChanged(int newHeight);
    void fontSizeChanged();
    void showBufferScrollIndicatorChanged();

public slots:
    void redraw();
    void updateTermSize();

private:
    Q_DISABLE_COPY(TextRender)

    void paintFromBuffer(QPainter* painter, QList<QList<TermChar> >& buffer, int from, int to, int &y);
    void drawBgFragment(QPainter* painter, int x, int y, int width, TermChar style);
    void drawTextFragment(QPainter* painter, int x, int y, QString text, TermChar style);
    QPoint charsToPixels(QPoint pos);

    int iWidth;
    int iHeight;
    QFont iFont;
    int iFontWidth;
    int iFontHeight;
    int iFontDescent;
    bool iShowBufferScrollIndicator;

    Terminal *iTerm;
    Util *iUtil;

    QList<QColor> iColorTable;
};

#endif // TEXTRENDER_H

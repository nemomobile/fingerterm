QT += core gui qml quick dbus feedback

TARGET = fingerterm
DEPENDPATH += .
INCLUDEPATH += .
LIBS += -lutil

CONFIG += sailfishapp

HEADERS += \
    ptyiface.h \
    terminal.h \
    textrender.h \
    version.h \
    util.h \
    keyloader.h

SOURCES += main.cpp terminal.cpp textrender.cpp \
    ptyiface.cpp \
    util.cpp \
    keyloader.cpp

OTHER_FILES += \
    qml/Main.qml \
    qml/Keyboard.qml \
    qml/Key.qml \
    qml/Lineview.qml \
    qml/Button.qml \
    qml/MenuFingerterm.qml \
    qml/NotifyWin.qml \
    qml/UrlWindow.qml \
    qml/LayoutWindow.qml

userdata.files = data
userdata.path = /usr/share/$${TARGET}
INSTALLS += userdata

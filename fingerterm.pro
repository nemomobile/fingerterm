QT += core gui qml quick dbus feedback

TARGET = fingerterm
DEPENDPATH += .
INCLUDEPATH += .
LIBS += -lutil

CONFIG += c++11
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

OTHER_FILES += $$files{qml/*}

userdata.files = data
userdata.path = /usr/share/$${TARGET}
INSTALLS += userdata

TARGET = fingerterm

CONFIG += sailfishapp
CONFIG += c++11

DEPENDPATH += src
INCLUDEPATH += src

SOURCES += $$files(src/*.cpp)
HEADERS += $$files(src/*.h)

# For forkpty()
LIBS += -lutil

OBJECTS_DIR = obj
MOC_DIR = obj

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

#include "qplatformdefs.h"

#include <QtQuick>

#include <sailfishapp.h>

#include <QtGui>
#include <QtQml>

extern "C" {
#include <pty.h>
#include <stdlib.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>
}

#include "ptyiface.h"
#include "terminal.h"
#include "textrender.h"
#include "util.h"
#include "version.h"
#include "keyloader.h"

void defaultSettings(QSettings* settings);
void copyFilesFromPath(QString from, QString to);

int main(int argc, char *argv[])
{
    QSettings *settings = new QSettings(QDir::homePath()+"/.config/FingerTerm/settings.ini", QSettings::IniFormat);
    defaultSettings(settings);

    // fork the child process before creating QGuiApplication
    int socketM;
    int pid = forkpty(&socketM,NULL,NULL,NULL);
    if( pid==-1 ) {
        qFatal("forkpty failed");
        exit(1);
    } else if( pid==0 ) {
        setenv("TERM", settings->value("terminal/envVarTERM").toByteArray(), 1);

        QString execCmd;
        int loginShell = 0;
        for(int i=0; i<argc-1; i++) {
            if( QString(argv[i]) == "-e" )
                execCmd = QString(argv[i+1]);
        }
        if(execCmd.isEmpty()) {
            execCmd = settings->value("general/execCmd").toString();
        }
        if(execCmd.isEmpty()) {
            // unset $POSIXLY_CORRECT to avoid bash going into restricted mode
            unsetenv("POSIXLY_CORRECT");
            // execute the user's default shell
            passwd *pwdstruct = getpwuid(getuid());
            execCmd = QString("exec ");
            execCmd.append(pwdstruct->pw_shell);
            execCmd.append(" --login");
            loginShell = 1;
        }

        if(settings)
            delete settings; // don't need 'em here

        QStringList execParts;
        if(loginShell) {
            execParts << "sh" << "-c" << execCmd;
        } else  {
            execParts = execCmd.split(' ', QString::SkipEmptyParts);
        }

        if(execParts.length()==0)
            exit(0);
        char *ptrs[execParts.length()+1];
        for(int i=0; i<execParts.length(); i++) {
            ptrs[i] = new char[execParts.at(i).toLatin1().length()+1];
            memcpy(ptrs[i], execParts.at(i).toLatin1().data(), execParts.at(i).toLatin1().length());
            ptrs[i][execParts.at(i).toLatin1().length()] = 0;
        }
        ptrs[execParts.length()] = 0;

        execvp(execParts.first().toLatin1(), ptrs);
        exit(0);
    }

    QGuiApplication *app = static_cast<QGuiApplication *>(SailfishApp::application(argc, argv));

    QScreen* sc = app->primaryScreen();
    if(sc){
    sc->setOrientationUpdateMask(Qt::PrimaryOrientation
                                 | Qt::LandscapeOrientation
                                 | Qt::PortraitOrientation
                                 | Qt::InvertedLandscapeOrientation
                                 | Qt::InvertedPortraitOrientation);
    }

    qmlRegisterType<TextRender>("TextRender",1,0,"TextRender");
    QQuickView *view = SailfishApp::createView();

    Terminal term;
    Util util(settings);
    term.setUtil(&util);
    QString startupErrorMsg;

    // copy the default config files to the config dir if they don't already exist
    copyFilesFromPath(SailfishApp::pathTo("data").toLocalFile(), util.configPath());

    KeyLoader keyLoader;
    keyLoader.setUtil(&util);
    bool ret = keyLoader.loadLayout( settings->value("ui/keyboardLayout").toString() );
    if(!ret) {
        // on failure, try to load the default one (english) directly from resources
        startupErrorMsg = "There was an error loading the keyboard layout.<br>\nUsing the default one instead.";
        settings->setValue("ui/keyboardLayout", "english");
        ret = keyLoader.loadLayout(":/data/english.layout");
        if(!ret)
            qFatal("failure loading keyboard layout");
    }

    QQmlContext *context = view->rootContext();
    context->setContextProperty( "term", &term );
    context->setContextProperty( "util", &util );
    context->setContextProperty( "keyLoader", &keyLoader );

    view->setSource(SailfishApp::pathTo("qml/Main.qml"));

    QObject *root = view->rootObject();
    if(!root)
        qFatal("no root object - qml error");

    QObject* win = root->findChild<QObject*>("window");

    if(!startupErrorMsg.isEmpty())
        QMetaObject::invokeMethod(win, "showErrorMessage", Qt::QueuedConnection, Q_ARG(QVariant, startupErrorMsg));

    TextRender *tr = root->findChild<TextRender*>("textrender");
    tr->setUtil(&util);
    tr->setTerminal(&term);
    term.setRenderer(tr);
    term.setWindow(view);
    util.setWindow(view);
    util.setTerm(&term);
    util.setRenderer(tr);

    QObject::connect(&term,SIGNAL(displayBufferChanged()),win,SLOT(displayBufferChanged()));
    QObject::connect(view->engine(),SIGNAL(quit()),app,SLOT(quit()));

    QSize screenSize = QGuiApplication::primaryScreen()->size();
    if ((screenSize.width() < 1024 || screenSize.height() < 768 || app->arguments().contains("-fs"))
            && !app->arguments().contains("-nofs"))
    {
        view->showFullScreen();
    } else {
        view->show();
    }

    PtyIFace ptyiface(pid, socketM, &term,
                       settings->value("terminal/charset").toString());

    if( ptyiface.failed() )
        qFatal("pty failure");

    return app->exec();
}

void defaultSettings(QSettings* settings)
{
    QMap<QString, QVariant> defaults;

    defaults["ui/orientationLockMode"] = "auto";
    defaults["general/execCmd"] = "";
    defaults["general/visualBell"] = true;
    defaults["general/backgroundBellNotify"] = true;
    defaults["general/grabUrlsFromBackbuffer"] = false;

    defaults["terminal/envVarTERM"] = "xterm";
    defaults["terminal/charset"] = "UTF-8";

    defaults["ui/keyboardLayout"] = "english";
    defaults["ui/fontFamily"] = "Droid Sans Mono";
    defaults["ui/fontSize"] = 11;
    defaults["ui/keyboardMargins"] = 10;
    defaults["ui/allowSwipe"] = "auto";   // "true", "false", "auto"
    defaults["ui/keyboardFadeOutDelay"] = 4000;
    defaults["ui/showExtraLinesFromCursor"] = 1;
    defaults["ui/vkbShowMethod"] = "move";  // "fade", "move", "off"
    defaults["ui/keyPressFeedback"] = true;
    defaults["ui/dragMode"] = "scroll";  // "gestures, "scroll", "select" ("off" would also be ok)

    defaults["state/showWelcomeScreen"] = true;
    defaults["state/createdByVersion"] = PROGRAM_VERSION;

    defaults["gestures/panLeftTitle"] = "Alt-Right";
    defaults["gestures/panLeftCommand"] = "\\e\\e[C";
    defaults["gestures/panRightTitle"] = "Alt-Left";
    defaults["gestures/panRightCommand"] = "\\e\\e[D";
    defaults["gestures/panUpTitle"] = "Page Down";
    defaults["gestures/panUpCommand"] = "\\e[6~";
    defaults["gestures/panDownTitle"] = "Page Up";
    defaults["gestures/panDownCommand"] = "\\e[5~";

    foreach (QString key, defaults.keys()) {
        if (!settings->contains(key)) {
            settings->setValue(key, defaults.value(key));
        }
    }
}

void copyFilesFromPath(QString from, QString to)
{
    QDir fromDir(from);
    QDir toDir(to);

    // Copy files from fromDir to toDir, but don't overwrite existing ones
    foreach (const QString &filename, fromDir.entryList(QDir::Files)) {
        QFile(fromDir.filePath(filename)).copy(toDir.filePath(filename));
    }
}

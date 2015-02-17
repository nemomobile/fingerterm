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
#include "keyloader.h"

void defaultSettings(QSettings* settings);

int main(int argc, char *argv[])
{
    // fork the child process before creating QGuiApplication
    int socketM;
    int pid = forkpty(&socketM,NULL,NULL,NULL);
    if( pid==-1 ) {
        qFatal("forkpty failed");
        exit(1);
    } else if( pid==0 ) {
        setenv("TERM", "xterm", 1);

        QString execCmd;
        int loginShell = 0;
        for(int i=0; i<argc-1; i++) {
            if( QString(argv[i]) == "-e" )
                execCmd = QString(argv[i+1]);
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

    QSettings settings;
    defaultSettings(&settings);

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
    Util util(&settings);
    term.setUtil(&util);
    QString startupErrorMsg;

    KeyLoader keyLoader(&util);
    keyLoader.loadDefaultLayout();

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

    view->show();

    PtyIFace ptyiface(pid, socketM, &term, "UTF-8");

    if( ptyiface.failed() )
        qFatal("pty failure");

    return app->exec();
}

void defaultSettings(QSettings* settings)
{
    QMap<QString, QVariant> defaults;

    defaults["general/execCmd"] = "";
    defaults["general/backgroundBellNotify"] = true;
    defaults["general/grabUrlsFromBackbuffer"] = false;

    defaults["ui/keyboardLayout"] = "shell";
    defaults["ui/fontSize"] = 11;
    defaults["ui/keyboardMargins"] = 10;
    defaults["ui/keyboardFadeOutDelay"] = 4000;
    defaults["ui/dragMode"] = "scroll";  // "gestures, "scroll", "select" ("off" would also be ok)

    defaults["state/showWelcomeScreen"] = true;

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

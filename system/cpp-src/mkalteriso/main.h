#ifndef MAIN_H
#define MAIN_H
//include headers
#include <iostream>
#include <QTimer>
#include <QtCore/QCoreApplication>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <QCommandLineParser>
#include "build_setting.h"
#include "command_collection.h"
int main(int argc,char* argv[]);
bool isroot();
class AppMain : public QObject
{
  Q_OBJECT

public:
  AppMain(QObject *parent, QCoreApplication* coreApp);
  build_setting build_setting_obj;

  command_collection cmd_collect;
public slots:
  void run();

private:
  QCoreApplication* app=nullptr;
  struct utsname uname_strkun;
};


#endif // MAIN_H

#ifndef CUSTOM_SYSTEM_EXEC_H
#define CUSTOM_SYSTEM_EXEC_H
#include <QStringList>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
char** QStringList_to_charpp(QStringList);
char** QStringList_to_charpp_null();
int custom_exec(QString file_name,QStringList args);
int custom_exec(QStringList args);
#endif // CUSTOM_SYSTEM_EXEC_H

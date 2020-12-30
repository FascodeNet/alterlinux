#include "custom_system_exec.h"
char** QStringList_to_charpp(QStringList qlkun){
    std::vector<std::string> qllistkun;
    for(QString strkun:qlkun){
        qllistkun.push_back(strkun.toStdString());
    }
    char** resultkun=NULL;
    resultkun=new char*[qllistkun.size() + 1];
    for(size_t i=0;i<qllistkun.size();i++){
        resultkun[i]=(char*)qllistkun[i].c_str();
    }
    return resultkun;
}
char** QStringList_to_charpp_null(QStringList qlkun){
    std::vector<std::string> qllistkun;
    for(QString strkun:qlkun){
        qllistkun.push_back(strkun.toStdString());
    }
    char** resultkun=NULL;
    resultkun=new char*[qllistkun.size() + 2];
    for(size_t i=0;i<qllistkun.size();i++){
        resultkun[i]=(char*)qllistkun[i].c_str();
    }
    resultkun[qllistkun.size()]=NULL;
    return resultkun;
}
int custom_exec(QString file_name,QStringList args){
    QStringList lskun22=args;
    lskun22.push_front(file_name);
    return custom_exec(lskun22);
}
int custom_exec(QStringList args){

    std::vector<std::string> qllistkun;
    for(QString strkun:args){
        qllistkun.push_back(strkun.toStdString());
    }
    char** argskun=NULL;
    argskun=new char*[qllistkun.size() + 2];
    for(size_t i=0;i<qllistkun.size();i++){
        argskun[i]=(char*)qllistkun[i].c_str();
    }
    argskun[qllistkun.size()]=NULL;
    pid_t pid = fork();
    if(pid < 0){
        perror("fork");
        exit(-1);
    }else if(pid == 0){
        execvp(argskun[0],argskun);
        perror("exec");
        exit(-1);
    }
    int status;
    pid_t resultkun=waitpid(pid,&status,0);
    if(resultkun < 0){
        perror("waitpid error");
        exit(-1);
    }
    return status;
}

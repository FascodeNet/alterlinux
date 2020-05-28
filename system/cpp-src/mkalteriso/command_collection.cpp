#include "command_collection.h"

command_collection::command_collection(QObject *parent) : QObject(parent)
{

}
void command_collection::set_build_setting(build_setting* bss){
    bskun=bss;
}
int command_collection::command_init(){
    _show_config(INIT);
    return 0;
}
int command_collection::command_install(){
    QFileInfo finfo(bskun->get_pacman_conf());
    if(!finfo.exists()){
        _msg_err("Pacman config file '" + bskun->get_pacman_conf() + "' does not exist");
        return 1;
    }
    _show_config(INSTALL);
    QString pkgls=bskun->get_pkg_list();
    pkgls=pkgls.simplified();
    if(pkgls == ""){
        _msg_err("Packages must be specified");
        return 2;
    }
    _chroot_init();
    return 0;

}
int command_collection::_chroot_init(){
    QDir dir(bskun->get_work_dir());
    if(!dir.exists("airootfs")){
        dir.mkpath("airootfs");
    }
    _pacman("base base-devel syslinux");
}
int command_collection::_pacman(QString packages){
    _msg_info("Installing packages to '" + bskun->get_work_dir() + "/airootfs/'...");
    packages=packages.replace(";","");
    QString safe_pacman_conf=bskun->get_pacman_conf();
    safe_pacman_conf=safe_pacman_conf.replace(";","");
    QString safe_workdir=bskun->get_work_dir();
    safe_workdir=safe_workdir.replace(";","");
    QString command_strkun="pacstrap -C \"" + safe_pacman_conf +"\" -c -G -M \"" +safe_workdir + "/airootfs\" " + packages;
    std::wcout << "Running pacstrap......\n" << command_strkun.toStdWString() << std::endl;
    system(command_strkun.toUtf8().data());
    return 0;
}
void command_collection::_show_config(show_config_type typekun){
    _msg_info("Configuration settings");
    _msg_info("               Command:\t" + bskun->get_command_args().at(0));
    _msg_info("          Architecture:\t" + bskun->get_architecture());
    _msg_info("     Working directory:\t" + bskun->get_work_dir());
    _msg_info("Installation directory:\t" + bskun->get_install_dir());
    switch(typekun){
    case INIT:
        _msg_info("    Pacman config file:\t" + bskun->get_pacman_conf());
        break;
    case INSTALL:
        _msg_info("    Pacman config file:\t" + bskun->get_pacman_conf());
        _msg_info("              Packages:\t" + bskun->get_pkg_list());
        break;
    }
}
void command_collection::_msg_info(QString s){
    std::wcout << "[mkalteriso] INFO: " << s.toStdWString() << std::endl;
}
void command_collection::_msg_err(QString s){
    std::wcerr << "[mkalteriso] ERROR: " << s.toStdWString() << std::endl;
}

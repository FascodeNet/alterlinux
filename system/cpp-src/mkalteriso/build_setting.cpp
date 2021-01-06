#include "build_setting.h"

build_setting::build_setting(QObject *parent) : QObject(parent)
{

}
//read and write interface
QString build_setting::get_architecture(){
    return architecture;
}
void build_setting::set_architecture(QString str){
    architecture=str;
}
QString build_setting::get_pacman_conf(){
    return pacman_conf;
}
void build_setting::set_pacman_conf(QString str){
    pacman_conf=str;
}
QString build_setting::get_install_dir(){
    return install_dir;
}
void build_setting::set_install_dir(QString str){
    install_dir=str;
}
QString build_setting::get_out_dir(){
    return out_dir;
}
void build_setting::set_out_dir(QString str){
    out_dir=str;
}
QString build_setting::get_work_dir(){
    return work_dir;
}
void build_setting::set_work_dir(QString str){
    work_dir=str;
}
QString build_setting::get_sfs_mode(){
    return sfs_mode;
}
void build_setting::set_sfs_mode(QString str){
    sfs_mode=str;
}
QString build_setting::get_sfs_comp(){
    return sfs_comp;
}
void build_setting::set_sfs_comp(QString str){
    sfs_comp=str;
}
QString build_setting::get_sfs_comp_opt(){
    return sfs_comp_opt;
}
void build_setting::set_sfs_comp_opt(QString str){
    sfs_comp_opt=str;
}
QString build_setting::get_pkg_list(){
    return pkg_list;
}
void build_setting::set_pkg_list(QString str){
    pkg_list=str;
}
QString build_setting::get_run_cmd(){
    return run_cmd;
}
void build_setting::set_run_cmd(QString str){
    run_cmd=str;
}
QString build_setting::get_iso_label(){
    return iso_label;
}
void build_setting::set_iso_label(QString str){
    iso_label=str;
}
QString build_setting::get_iso_publisher(){
    return iso_publisher;
}
void build_setting::set_iso_publisher(QString s){
    iso_publisher=s;
}
QString build_setting::get_iso_application(){
    return iso_application;
}
void build_setting::set_iso_application(QString s){
    iso_application=s;
}
bool build_setting::get_quiet(){
    return quiet;
}
void build_setting::set_quiet(bool b){
    quiet=b;
}
QString build_setting::get_gpg_key(){
    return gpg_key;
}
void build_setting::set_gpg_key(QString s){
    gpg_key=s;
}
bool build_setting::get_use_gpg_key(){
    return use_gpg_key;
}
void build_setting::set_use_gpg_key(bool b){
    use_gpg_key=b;
}
QStringList build_setting::get_command_args(){
    return command_args;
}
void build_setting::set_command_args(QStringList sl){
    command_args=sl;
}
bool build_setting::get_debug_mode(){
    return debug_mode;
}
void build_setting::set_debug_mode(bool b){
    debug_mode=b;
}
bool build_setting::get_wsl(){
    return enable_wsl;
}
void build_setting::set_wsl(bool blkun){
    enable_wsl=blkun;
}
bool build_setting::get_aur(){
    return enable_aur;
}
void build_setting::set_aur(bool bl){
    enable_aur=bl;
}

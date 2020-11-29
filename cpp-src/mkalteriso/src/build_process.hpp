#pragma once

#include <string>
#include <vector>
#include "message.hpp"
#include <sys/stat.h>
#include <sys/types.h>
#include <fstream>
#include <filesystem>
#include "custom_exec.hpp"
#include "path_lib.hpp"
#include <time.h>
#define String std::string
#define Vector std::vector
void _msg_error(String);
void _msg_info(String);
void _msg_warn(String);
void _msg_debug(String);
void test_conf();
void _show_config();
bool dir_exist(String dir_name);
int str_mkdir(String,unsigned short);
struct build_option{
    String app_name="mkalteriso";
    String install_dir=app_name;
    String iso_label="mkalteriso";
    String iso_publisher="Fascode Network";
    String gpg_key="";
    String out_dir="out";
    String aditional_packages="";
    String work_dir="work";
    String pacman_conf="/etc/pacman.conf";
    String run_cmd="";
    String profile="";
    String airootfs_dir="";
    String isofs_dir="";
    String iso_name="";
    Vector<String> bootmodes;
    String iso_application="";
    String iso_version="";
    String arch="x86_64";
    bool isreleng=false;
    Vector<String> packages_vector;
    Vector<String> aur_packages_vector;
    time_t SOURCE_DATE_EPOCH;
    String img_name=".iso";
    int airootfs_mb=4096;
};

void setup(build_option);
void _build_profile();
template<class Fn> void _run_once(Fn,String);
void _make_pacman_conf();
void _make_custom_airootfs();
String popen_auto(String cmd_str);
void force_umount();
int exit_force(int);
void _make_and_mount_airootfs_folder();
int truncate_str(String,off_t);
void _make_packages();
void _make_packages_aur();
void _pacman(Vector<String>);
#pragma once
#include <iostream>
#include "cmdline.h"
#include <string>
#include <vector>
#include <stdlib.h>
#include <fstream>

#define READ  (0)
#define WRITE (1)

#include <unistd.h>
#include "path_lib.hpp"
#define String std::string
#define Vector std::vector
#include "message.hpp"
#include "custom_exec.hpp"
#include "json.hpp"
#include <regex>
#include <filesystem>
void _msg_error(String);
void _msg_info(String);
void _msg_warn(String);
void _msg_debug(String);
void parse_channel();
Vector<String> parse_packages(String packages_file_path);
Vector<String> parse_packages_folder(String packages_folder_path);
Vector<String> parse_packages_folder(Vector<String> base_vect,String packages_folder_path);
Vector<String> parse_packages(Vector<String> base_vector,String packages_file_path);

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
#pragma once
#include <iostream>
#include "cmdline.h"
#include <string>
#include <vector>
#define String std::string
#define Vector std::vector
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
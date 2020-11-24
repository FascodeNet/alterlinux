#pragma once
#include <iostream>
#include "cmdline.h"
#include <string>
#include <vector>
#include <stdlib.h>
#include <fstream>
#include <time.h>

#define READ  (0)
#define WRITE (1)

#include <unistd.h>
#include "path_lib.hpp"
#include "custom_exec.hpp"
#include "json.hpp"
#include <regex>
#include <filesystem>
#include "build_process.hpp"
void parse_channel();
Vector<String> parse_packages(String packages_file_path);
Vector<String> parse_packages_folder(String packages_folder_path);
Vector<String> parse_packages_folder(Vector<String> base_vect,String packages_folder_path);
Vector<String> parse_packages(Vector<String> base_vector,String packages_file_path);

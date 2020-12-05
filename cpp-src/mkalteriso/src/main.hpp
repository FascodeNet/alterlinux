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
#include "check_depends.hpp"
void parse_channel();
Vector<String> parse_packages(String packages_file_path);
Vector<String> parse_packages_folder(String packages_folder_path);
Vector<String> parse_packages_folder(Vector<String> base_vect,String packages_folder_path);
Vector<String> parse_packages(Vector<String> base_vector,String packages_file_path);
void set_lang(String);
/**
 * @fn
 * lang_info作成用
 * @param lang_name 内部識別名
 * @param locale_gen localegen用
 * @param long_name 長い名前
 * @param timezonekun timezone名
 */

lang_info gen_lang_list(String lang_name,String locale_gen,String timezonekun,String long_name);
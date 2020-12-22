#pragma once
#include "ThreadPool.h"
#include <filesystem>
#include <iostream>
struct kernel_opt{
    std::string kernel_name;
    std::string description;
    std::string vmlinuz_name;
    std::string initramfs_name;
    std::string package_name;
    std::string preset_name;
};
std::vector<kernel_opt> get_kernel_list(std::string kernel_dir);
class kernel_tool{

};
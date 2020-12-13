#include "kernel_tool.hpp"
#include <sys/stat.h>
bool _dir_exist(std::string dir_name){
    const char *dir = dir_name.c_str();
    struct stat statBuf;
    if(stat(dir,&statBuf)==0){
        return true;
    }else{
        return false;
    }
}
std::vector<kernel_opt> get_kernel_list(std::string kernel_dir){
    std::vector<kernel_opt> kernel_vect;
    for(const std::filesystem::directory_entry &i:std::filesystem::directory_iterator(kernel_dir)){
        if(i.is_directory()){
            if(_dir_exist(i.path().string() + "/manifest.json")){
                kernel_opt kernelkun;
                
            }
        }
    }
    return kernel_vect;

}
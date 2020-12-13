#include "kernel_tool.hpp"
#include "json.hpp"
#include <fstream>
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
                std::ifstream json_stream(i.path().string() + "/manifest.json");
                std::string json_data=std::string(std::istreambuf_iterator<char>(json_stream),
                    std::istreambuf_iterator<char>());
                nlohmann::json json_obj;
                try{
                    json_obj=nlohmann::json::parse(json_data);
                }catch(nlohmann::json::parse_error msg){
                    //stub
                }
                kernelkun.kernel_name=json_obj["name"].get<std::string>();
                kernelkun.package_name=json_obj["package"].get<std::string>();
                kernelkun.vmlinuz_name=json_obj["vmlinuz_name"].get<std::string>();
                kernelkun.initramfs_name=json_obj["initramfs_name"].get<std::string>();
                kernelkun.description=json_obj["description"].get<std::string>();
                kernel_vect.push_back(kernelkun);
            }
        }
    }
    return kernel_vect;

}
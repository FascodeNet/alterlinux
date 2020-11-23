#include "path_lib.hpp"
std::string realpath(std::string origpath){
    char* result_path=realpath(origpath.c_str(),NULL);
    if(result_path==NULL){
        return "ERR";
    }else{
        std::string result_path_s=result_path;
        free(result_path);
        return result_path_s;
    }
}
#pragma once
#include <vector>
#include <string>
#include <wait.h>
#include <stdlib.h>
#include <initializer_list>
#include <unistd.h>
namespace FascodeUtil{
    int custom_exec_v(std::vector<std::string> args);
    int custom_exec_v(std::string,std::vector<std::string> args);
    int custom_exec_v(char*,std::vector<std::string> args);
    template<class... T> 
    int custom_exec(T... args);
    int custom_exec_v_no_wait(std::vector<std::string> args);
    template<class... T> 
    int custom_exec_no_wait(T... args);
}
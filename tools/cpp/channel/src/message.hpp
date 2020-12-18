#pragma once
#include <iostream>
#include <ostream>
#include <string>
namespace FascodeUtil{
    enum MSG_TYPE{
        INFO=0,
        ERR=1,
        DEBUG=2,
        WARN=3
    };
    enum COLOR_TYPE{
        BLACK=30,
        RED=31,
        GREEN=32,
        YELLOW=33,
        BLUE=34,
        MAGENTA=35,
        CYAN=36,
        WHITE=37
    };
    class msg{
        public:
            void print(MSG_TYPE,std::string appname,std::string character,std::string label,COLOR_TYPE color,int numberspace,std::string message);
            void print(MSG_TYPE,std::string appname,std::string character,int numberspace,std::string message);
            void print(MSG_TYPE,std::string appname,int numberspace,std::string message);
            void print(MSG_TYPE,std::string appname,std::string character,std::string message);
            void print(MSG_TYPE,std::string appname,std::string message);

        private:
            void _print(std::ostream& out_stream,std::string appname,std::string character,std::string label,COLOR_TYPE color,int numberspace,std::string message);
            void _echo_type(std::ostream& out_stream,std::string character,std::string label,int label_space,COLOR_TYPE color);
        
    };

}
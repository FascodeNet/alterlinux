#include "message.hpp"
namespace FascodeUtil{
    void msg::print(MSG_TYPE msgtype,std::string appname,std::string character,int numberspace,std::string message){
        switch(msgtype){
            case ERR:
                print(msgtype,appname,character,"Error",RED,numberspace,message);
                break;
            case INFO:
                print(msgtype,appname,character,"Info",GREEN,numberspace,message);
                break;
            case DEBUG:
                print(msgtype,appname,character,"Debug",MAGENTA,numberspace,message);
                break;
            case WARN:
                print(msgtype,appname,character,"Warning",YELLOW,numberspace,message);
                break;
        }
    }
    void msg::print(MSG_TYPE msgtype,std::string appname,std::string character,std::string label,COLOR_TYPE color,int numberspace,std::string message){
        if(msgtype == ERR){
            _print(std::cerr,appname,character,label,color,numberspace,message);
        }else{
            _print(std::cout,appname,character,label,color,numberspace,message);
        }
    }
    void msg::_print(std::ostream& out_stream,std::string appname,std::string character,std::string label,COLOR_TYPE color,int numberspace,std::string message){

        out_stream << "\e[36m[" << appname << "]\e[m ";
        _echo_type(out_stream,character,label,numberspace,color);
        out_stream << message << std::endl;
    }
    void msg::_echo_type(std::ostream& out_stream,std::string character,std::string label,int label_space,COLOR_TYPE color){
        int word_count=label.length();
        bool nolabel=false;
        bool noadjust=false;
        bool nocolor=false;
        if(!nolabel){
            if(!noadjust){
                for(int i=0;i<(label_space - word_count);i++){
                    out_stream << character ;
                }
            }
            if(nocolor){
                out_stream << label;
            }else{
                out_stream << "\e[" << color << "m" << label << "\e[0m ";
            }
        }
    }
    void msg::print(MSG_TYPE msgtype,std::string appname,int numberspace,std::string message){
        print(msgtype,appname," ",numberspace,message);
    }
    void msg::print(MSG_TYPE msgtype,std::string appname,std::string character,std::string message){
        print(msgtype,appname,character,7,message);
    }
    void msg::print(MSG_TYPE msgtype,std::string appname,std::string message){
        print(msgtype,appname," ",message);
    }
}
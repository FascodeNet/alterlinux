#include "main.hpp"
int main(int argc,char* argv[]){
    cmdline::parser p;
    p.footer("[command]");
    p.add("arch",'a',"Specify the architecture");
    p.add("help",'h',"This help message");
    p.add("nobuiltin",'b',"Exclude built-in channels");
    p.add("dirname",'d',"Display directory names of all channel as it is");
    p.add("fullpath",'f',"Display the full path of the channel (Use with -db)");
    p.add("kernel",'k',"Specify the supported kernel");
    p.add("multi",'m',"Ignore channel version");
    p.add("only-add",'o',"Only additional channels");
    p.add("version",'v',"Specifies the AlterISO version");
    p.add("nocheck",0,"Do not check the channel with desc command.This option helps speed up.");
    if (!p.parse(argc, argv)||p.exist("help")){
        std::cout<<p.error_full()<<p.usage();
        std::cout << "commands:" << std::endl;
        std::cout << "\tcheck [name]\tReturns whether the specified channel name is valid.\n";
        std::cout << "\tdesc  [name]\tDisplay a description of the specified channel\n";
        std::cout << "\tshow      \tDisplay a list of channels" << std::endl;
        return 1;   
    }
    
    return 0;
}
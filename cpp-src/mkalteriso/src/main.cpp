#include "main.hpp"
int main(int argc,char* argv[]){
    cmdline::parser p;
    p.add<std::string>("application",'A',"Set an application name for the ISO",false,app_name);
    p.add<std::string>("pacman_config",'C',"pacman configuration file.",false,pacman_conf);
    p.add("help", 'h', "This message");
    p.add<std::string>("install_dir",'D',"Set an install_dir. All files will by located here.\n\t\t\t NOTE: Max 8 characters, use only [a-z0-9]",
    false,install_dir);
    p.add<std::string>("iso_label",'L',"Set the ISO volume label",false,iso_label);
    p.add<std::string>("iso_pub",'P',"Set the ISO publisher",false,iso_publisher);
    p.add<std::string>("gpg-key",'g',"Set the GPG key to be used for signing the sqashfs image",false,"");
    p.add<std::string>("out_dir",'O',"Set the output directory",false,out_dir);
    p.add<std::string>("packages",'p',"Package(s) to install, can be used multiple times",false,aditional_packages);
    p.add("verbose",'v',"Enable verbose output");
    p.add<std::string>("work",'w',"Set the working directory",false,work_dir);
    if (!p.parse(argc, argv)||p.exist("help")){
        std::cout<<p.error_full()<<p.usage();
        return 0;
    }
    return 0;
}
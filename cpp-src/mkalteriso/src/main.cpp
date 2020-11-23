#include "main.hpp"
int main(int argc,char* argv[]){
    cmdline::parser p;
    p.add<String>("application",'A',"Set an application name for the ISO",false,app_name);
    p.add<String>("pacman_config",'C',"pacman configuration file.",false,pacman_conf);
    p.add("help", 'h', "This message");
    p.add<String>("install_dir",'D',"Set an install_dir. All files will by located here.\n\t\t\t NOTE: Max 8 characters, use only [a-z0-9]",
    false,install_dir);
    p.add<String>("iso_label",'L',"Set the ISO volume label",false,iso_label);
    p.add<String>("iso_pub",'P',"Set the ISO publisher",false,iso_publisher);
    p.add<String>("gpg-key",'g',"Set the GPG key to be used for signing the sqashfs image",false,"");
    p.add<String>("out_dir",'O',"Set the output directory",false,out_dir);
    p.add<String>("packages",'p',"Package(s) to install, can be used multiple times",false,aditional_packages);
    p.add("verbose",'v',"Enable verbose output");
    p.add<String>("work",'w',"Set the working directory",false,work_dir);
    p.add<String>("run_cmd",'r',"run command");
    if (!p.parse(argc, argv)||p.exist("help")){
        std::cout<<p.error_full()<<p.usage();
        return 0;
    }
    app_name=p.get<String>("application");
    pacman_conf=p.get<String>("pacman_config");
    install_dir=p.get<String>("install_dir");
    iso_label=p.get<String>("iso_label");
    iso_publisher=p.get<String>("iso_pub");
    gpg_key=p.get<String>("gpg-key");
    out_dir=p.get<String>("out_dir");
    aditional_packages=p.get<String>("packages");
    work_dir=p.get<String>("work");
    run_cmd=p.get<String>("run_cmd");
    return 0;
}
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
    Vector<String> cmd_ls=p.rest();
    if(cmd_ls.size()==0){
        _msg_error("No profile specified");
        return 0;
    }
    profile=realpath("./channels/" + cmd_ls.at(0));
    if(cmd_ls.at(0) == "releng"){
        isreleng=true;
    }
    airootfs_dir=work_dir + "/airootfs";
    isofs_dir=work_dir+"/iso";
    parse_channel();
    for(String bootmodekun:bootmodes){
        _msg_debug("bootmode : " + bootmodekun);
    }
    _msg_debug("pacman_conf : " + pacman_conf);
    for(String package_name:packages_vector){
        _msg_debug("package : " + package_name);
    }
    return 0;
}
void _msg_error(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::ERR,app_name,msg_con);
}
void _msg_info(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::INFO,app_name,msg_con);
}
void _msg_warn(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::WARN,app_name,msg_con);
}
void _msg_debug(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::DEBUG,app_name,msg_con);
}
void parse_channel(){
    Vector<String> argskun;
    argskun.push_back(realpath("./archiso/get_profile_def.sh"));
    argskun.push_back("-s");
    argskun.push_back(realpath("./archiso/json_template.json"));
    argskun.push_back("-p");
    argskun.push_back(realpath(profile + "/profiledef.sh"));
    argskun.push_back("-o");
    argskun.push_back(realpath("./.cache_channel_json.json"));
    FascodeUtil::custom_exec_v(argskun);
    std::ifstream json_stream(realpath("./.cache_channel_json.json"));
    remove(realpath("./.cache_channel_json.json").c_str());
    String json_data=String(std::istreambuf_iterator<char>(json_stream),
                            std::istreambuf_iterator<char>());
    nlohmann::json json_obj=nlohmann::json::parse(json_data);
    iso_name=json_obj["iso_name"].get<String>();
    iso_label=json_obj["iso_label"].get<String>();
    iso_publisher=json_obj["iso_publisher"].get<String>();
    iso_application=json_obj["iso_application"].get<String>();
    iso_version=json_obj["iso_version"].get<String>();
    install_dir=json_obj["install_dir"].get<String>();
    bootmodes=json_obj["bootmodes"].get<Vector<String>>();
    arch=json_obj["arch"].get<String>();
    char pathname[512];
    memset(pathname, '\0', 512); 
    getcwd(pathname,512);
    chdir(realpath(profile).c_str());
    packages_vector=parse_packages_folder("./packages." + arch);
    pacman_conf=realpath(json_obj["pacman_conf"].get<String>());
    chdir("../");
    if(!isreleng){
        packages_vector=parse_packages_folder(packages_vector,"./share/packages." + arch);
    }
    chdir(pathname);

}
Vector<String> parse_packages(String packages_file_path){
    Vector<String> return_collection;
    std::ifstream package_file_stream(packages_file_path);
    String line_buf;
    while(getline(package_file_stream,line_buf)){
        String replaced_space=std::regex_replace(line_buf,std::regex(" "),"");
        if(replaced_space.substr(0,1) != "#"){
            if(replaced_space != ""){
                return_collection.push_back(replaced_space);
            }
        }
    }
    return return_collection;
}
Vector<String> parse_packages(Vector<String> base_vector,String packages_file_path){
    std::ifstream package_file_stream(packages_file_path);
    String line_buf;
    while(getline(package_file_stream,line_buf)){
        String replaced_space=std::regex_replace(line_buf,std::regex(" "),"");
        if(replaced_space.substr(0,1) != "#"){
            if(replaced_space != ""){
                base_vector.push_back(replaced_space);
            }
        }
    }
    return base_vector;
}
bool ends_with(const std::string& str, const std::string& suffix) {
    size_t len1 = str.size();
    size_t len2 = suffix.size();
    return len1 >= len2 && str.compare(len1 - len2, len2, suffix) == 0;
}

Vector<String> parse_packages_folder(String packages_folder_path){
    Vector<String> return_object;
    std::filesystem::directory_iterator iter(packages_folder_path),end;
    std::error_code err;
    for(;iter != end && !err;iter.increment(err)){
        const std::filesystem::directory_entry entry=*iter;
        String fnamekun=entry.path().string();
        if(ends_with(fnamekun,arch)){
            return_object=parse_packages(return_object,fnamekun);
        }
    }
    if(err){
        _msg_error(err.message());
    }
    return return_object;
}
Vector<String> parse_packages_folder(Vector<String> base_vect,String packages_folder_path){
    std::filesystem::directory_iterator iter(packages_folder_path),end;
    std::error_code err;
    for(;iter != end && !err;iter.increment(err)){
        const std::filesystem::directory_entry entry=*iter;
        String fnamekun=entry.path().string();
        if(ends_with(fnamekun,arch)){
            base_vect=parse_packages(base_vect,fnamekun);
        }
    }
    if(err){
        _msg_error(err.message());
    }
    return base_vect;
}
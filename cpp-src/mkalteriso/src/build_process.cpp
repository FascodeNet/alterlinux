#include "build_process.hpp"
build_option bp2;
void setup(build_option bpkun){
    bp2=bpkun;
}
void test_conf(){
    for(String bootmodekun:bp2.bootmodes){
        _msg_debug("bootmode : " + bootmodekun);
    }
}
void _msg_error(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::ERR,bp2.app_name,msg_con);
}
void _msg_info(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::INFO,bp2.app_name,msg_con);
}
void _msg_warn(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::WARN,bp2.app_name,msg_con);
}
void _msg_debug(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::DEBUG,bp2.app_name,msg_con);
}
int str_mkdir(String dirname,unsigned short mode){
    return mkdir(dirname.c_str(),mode);
}
bool dir_exist(String dir_name){
    const char *dir = dir_name.c_str();
    struct stat statBuf;
    if(stat(dir,&statBuf)==0){
        return true;
    }else{
        return false;
    }
}
void _show_config(){
    struct tm *ptm;
    ptm=localtime(&bp2.SOURCE_DATE_EPOCH);
    char build_date[256] = {'\0'};
    try{
        strftime(build_date,sizeof(build_date),"%Y-%m-%dT%H:%M:%S%z",ptm);
    }catch (char* e){
        _msg_error("Error " + String(e));
        return;
    }
    _msg_info(bp2.app_name + " configuration settings");
    _msg_info("             Architecture:   " + bp2.arch);
    _msg_info("        Working directory:   " + bp2.work_dir);
    _msg_info("   Installation directory:   " + bp2.install_dir);
    _msg_info("               Build date:   " + String(build_date));
    _msg_info("         Output directory:   " + bp2.out_dir);
    _msg_info("                  Channel:   " + bp2.profile);
    _msg_info("Pacman configuration file:   " + bp2.pacman_conf);
    _msg_info("          Image file name:   " + bp2.img_name);
    _msg_info("         ISO volume label:   " + bp2.iso_label);
    _msg_info("            ISO publisher:   " + bp2.iso_publisher);
    _msg_info("          ISO application:   " + bp2.iso_application);

    _msg_info("               Boot modes:   ");
    for(String bootm:bp2.bootmodes){
        _msg_info("                             " + bootm);
    }
    _msg_info("                 Packages:   ");
    for(String pkgkun:bp2.packages_vector){
        _msg_info("                             " + pkgkun);
    }


}
void _make_pacman_conf(){
    String _system_cache_dirs=popen_auto("pacman-conf CacheDir| tr '\\n' ' '");
    String _profile_cache_dirs=popen_auto("pacman-conf --config \"" + bp2.pacman_conf + "\" CacheDir| tr '\\n' ' '");
    _msg_debug("system cache dir:" + _system_cache_dirs);
    _msg_debug("profile cache dir:" + _profile_cache_dirs);
    return;
}
String popen_auto(String cmd_str){
    char s[1024];
    FILE *fpin;
    fpin=popen(cmd_str.c_str(),"r");
    String result_str;
    while(fgets(s,sizeof(s),fpin) != NULL){
        result_str=result_str+s;
    }
    pclose(fpin);
    return result_str;

}
void _build_profile(){
    bp2.airootfs_dir=bp2.work_dir + "/" + bp2.arch + "/airootfs";
    bp2.isofs_dir=bp2.work_dir + "/iso";
    bp2.img_name=bp2.iso_name + "-" + bp2.iso_version + "-" + bp2.arch + ".iso";
    if(!dir_exist(bp2.work_dir)){
        str_mkdir(bp2.work_dir,S_IREAD | S_IWRITE);
    }
    {
        std::ofstream build_date_stream(bp2.work_dir + "/build_date");
        build_date_stream << std::to_string(bp2.SOURCE_DATE_EPOCH);
        build_date_stream.close();

    }
    _show_config();
    _run_once(_make_pacman_conf,"_make_pacman_conf");
    
}
template<class Fn> void _run_once(Fn func,String name){
    if(!dir_exist(bp2.work_dir + "/build." + name)){
        func();
    }
}
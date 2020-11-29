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
    String _cache_dirs;
    if(_profile_cache_dirs != "/var/cache/pacman/pkg" && _system_cache_dirs != _profile_cache_dirs){
        _cache_dirs=_profile_cache_dirs;
    }else{
        _cache_dirs=_system_cache_dirs;
    }
    _msg_info("Copying custom pacman.conf to work directory...");
    Vector<String> pacman_conf_args;
    pacman_conf_args.push_back("bash");
    pacman_conf_args.push_back("-c");
    pacman_conf_args.push_back("pacman-conf --config \"" + realpath(bp2.pacman_conf)
    + "\" | sed '/CacheDir/d;/DBPath/d;/HookDir/d;/LogFile/d;/RootDir/d' > \"" + realpath(bp2.work_dir) + "/pacman.conf\"");
    FascodeUtil::custom_exec_v(pacman_conf_args);
    _msg_info("Using pacman CacheDir: "+ _cache_dirs);
    Vector<String> sed_args;
    sed_args.push_back("sed");
    sed_args.push_back("/\\[options\\]/a CacheDir = " + _cache_dirs + "\n\t\t/\\[options\\]/a HookDir = " + bp2.airootfs_dir + "/etc/pacman.d/hooks/");
    sed_args.push_back("-i");
    sed_args.push_back(bp2.work_dir + "/pacman.conf");
    FascodeUtil::custom_exec_v(sed_args);
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
    bp2.img_name=bp2.iso_name + "-" + bp2.iso_version + "-" + bp2.arch + ".iso";
    if(!dir_exist(bp2.work_dir)){
        _msg_debug("mkdir result : " + std::to_string(str_mkdir(bp2.work_dir,S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH | S_IEXEC )));
    }
    {
        std::ofstream build_date_stream(bp2.work_dir + "/build_date");
        build_date_stream << std::to_string(bp2.SOURCE_DATE_EPOCH);
        build_date_stream.close();

    }

    bp2.isofs_dir=realpath(bp2.work_dir) + "/iso";
    bp2.airootfs_dir=realpath(bp2.work_dir) + "/" + bp2.arch + "/airootfs";
    _show_config();

    _run_once(_make_pacman_conf,"_make_pacman_conf");
    _run_once(_make_and_mount_airootfs_folder,"_make_and_mount_airootfs_folder");
    _run_once(_make_custom_airootfs,"_make_custom_airootfs");
    _run_once(_make_packages,"_make_packages");
    exit_force(0);
}
template<class Fn> void _run_once(Fn func,String name){
    if(!dir_exist(bp2.work_dir + "/build." + name)){
        std::ofstream(bp2.work_dir + "/build." + name);
        func();
    }
}
void _make_custom_airootfs(){

    if(dir_exist(realpath(bp2.profile).c_str())){
        _msg_info("Copying custom airootfs files and setting up user home directories...");
        Vector<String> cp_airootfs;
        cp_airootfs.push_back("cp");
        cp_airootfs.push_back("-af");
        cp_airootfs.push_back("--no-preserve=ownership");
        cp_airootfs.push_back("--");
        cp_airootfs.push_back(bp2.profile + "/airootfs/.");
        cp_airootfs.push_back(bp2.airootfs_dir);
        FascodeUtil::custom_exec_v(cp_airootfs);
    }
    if(dir_exist(realpath(bp2.profile + "../share/airootfs").c_str())){
        _msg_info("Copying custom airootfs files and setting up user home directories...");
        Vector<String> cp_airootfs;
        cp_airootfs.push_back("cp");
        cp_airootfs.push_back("-af");
        cp_airootfs.push_back("--no-preserve=ownership");
        cp_airootfs.push_back("--");
        cp_airootfs.push_back(bp2.profile + "../share/airootfs/.");
        cp_airootfs.push_back(bp2.airootfs_dir);
        FascodeUtil::custom_exec_v(cp_airootfs);
    }
    if(dir_exist(realpath(bp2.airootfs_dir + "/etc/shadow"))){
        chmod(realpath(bp2.airootfs_dir + "/etc/shadow").c_str(),0400);
    }
    if(dir_exist(realpath(bp2.airootfs_dir + "/etc/gshadow"))){
        chmod(realpath(bp2.airootfs_dir + "/etc/gshadow").c_str(),0400);
    }
    if(dir_exist(realpath(bp2.airootfs_dir + "/etc/passwd"))){
        std::ifstream passwd_stream(realpath(bp2.airootfs_dir + "/etc/passwd"));
        if(!passwd_stream.is_open()){
            _msg_error("Can't open " + realpath(bp2.airootfs_dir + "/etc/passwd"));
            return;
        }
        String line;
        while(getline(passwd_stream,line)){
            Vector<String> passwd=split_passwd(line);
            if(passwd.at(5) == "/") continue;
            if(passwd.at(5) == "") continue;
            if(dir_exist(bp2.airootfs_dir + "/" + passwd.at(5))){
                Vector<String> chown_args;
                chown_args.push_back("chown");
                chown_args.push_back("-hR");
                chown_args.push_back("--");
                chown_args.push_back(passwd.at(2) + ":" + passwd.at(3));
                chown_args.push_back(bp2.airootfs_dir + "/" + passwd.at(5));
                FascodeUtil::custom_exec_v(chown_args);
                Vector<String> chmod_args;
                chmod_args.push_back("chmod");
                chmod_args.push_back("-f");
                chmod_args.push_back("0750");
                chmod_args.push_back("--");
                chmod_args.push_back(bp2.airootfs_dir + "/" + passwd.at(5));
                FascodeUtil::custom_exec_v(chmod_args);
            }else{
                Vector<String> install_args;
                install_args.push_back("install");
                install_args.push_back("-d");
                install_args.push_back("-m");
                install_args.push_back("0750");
                install_args.push_back("-o");
                install_args.push_back(passwd.at(2));
                install_args.push_back("-g");
                install_args.push_back(passwd.at(3));
                install_args.push_back("--");
                install_args.push_back(bp2.airootfs_dir + "/" + passwd.at(5));
                FascodeUtil::custom_exec_v(install_args);
            }
        }
        passwd_stream.close();
    }
    _msg_info("Done!");
}
void force_umount(){
    _msg_info("Unmount work dir..");
    Vector<String> umount_vector;
    umount_vector.push_back("umount");
    umount_vector.push_back("-d");
    umount_vector.push_back("--");
    umount_vector.push_back(realpath(bp2.airootfs_dir));
    FascodeUtil::custom_exec_v(umount_vector);    
    _msg_info("Unmounted!");
    Vector<String> rmdir_vect;
    rmdir_vect.push_back("rmdir");
    rmdir_vect.push_back("--");
    rmdir_vect.push_back(realpath(bp2.airootfs_dir));
    signal(SIGHUP, nothing_handler);
    signal(SIGINT, nothing_handler);
    signal(SIGTERM, nothing_handler);
    signal(SIGKILL, nothing_handler);
}
void nothing_handler(int a){
    //nothing to do
}
int exit_force(int c){
    force_umount();
    return c;
}
void _make_and_mount_airootfs_folder(){
    _msg_info("airootfs.img gen...");
    _msg_info("size : " + std::to_string(bp2.airootfs_mb) + "MB");
    Vector<String> mkfs_ext4_args;
    mkfs_ext4_args.push_back("mkfs.ext4");
    mkfs_ext4_args.push_back("-O");
    mkfs_ext4_args.push_back("^has_journal,^resize_inode");
    mkfs_ext4_args.push_back("-E");
    mkfs_ext4_args.push_back("lazy_itable_init=0");
    mkfs_ext4_args.push_back("-m");
    mkfs_ext4_args.push_back("0");
    mkfs_ext4_args.push_back("-F");
    mkfs_ext4_args.push_back("--");
    mkfs_ext4_args.push_back(realpath(bp2.work_dir) + "/airootfs.img");
    mkfs_ext4_args.push_back(std::to_string(bp2.airootfs_mb) + "M");
    FascodeUtil::custom_exec_v(mkfs_ext4_args);
    _msg_info("Generated airootfs.img");
    _msg_info("tune2fs...");
    Vector<String> tune2fs_args;
    tune2fs_args.push_back("tune2fs");
    tune2fs_args.push_back("-c");
    tune2fs_args.push_back("0");
    tune2fs_args.push_back("-i");
    tune2fs_args.push_back("0");
    tune2fs_args.push_back("--");
    tune2fs_args.push_back(realpath(bp2.work_dir) + "/airootfs.img");
    FascodeUtil::custom_exec_v(tune2fs_args);
    _msg_info("Done!");
    _msg_info("mount airootfs.img...");
    signal(SIGHUP, trap_handler);
    signal(SIGINT, trap_handler);
    signal(SIGTERM, trap_handler);
    signal(SIGKILL, trap_handler);
    Vector<String> install_airoofs;
    install_airoofs.push_back("install");
    install_airoofs.push_back("-d");
    install_airoofs.push_back("-m");
    install_airoofs.push_back("0755");
    install_airoofs.push_back("--");
    install_airoofs.push_back(bp2.airootfs_dir);
    FascodeUtil::custom_exec_v(install_airoofs);
    _msg_info("Mounting " + realpath(bp2.work_dir) + "/airootfs.img" + " on " + bp2.airootfs_dir +  "...");
    Vector<String> mount_args;
    mount_args.push_back("mount");
    mount_args.push_back("--");
    mount_args.push_back(realpath(bp2.work_dir) + "/airootfs.img");
    mount_args.push_back(bp2.airootfs_dir);
    FascodeUtil::custom_exec_v(mount_args);
    _msg_info("Done!");

}
int truncate_str(String pathkun,off_t lenghtkun){
    return truncate(pathkun.c_str(),lenghtkun);
}
void _make_packages(){
    _pacman(bp2.packages_vector);
}
void _pacman(Vector<String> packages){
    _msg_info("Installing packages to " + bp2.airootfs_dir + "/...");
    Vector<String> pacstrap_args;
    pacstrap_args.push_back("pacstrap");
    pacstrap_args.push_back("-C");
    pacstrap_args.push_back(realpath(bp2.work_dir + "/pacman.conf"));
    pacstrap_args.push_back("-c");
    pacstrap_args.push_back("-G");
    pacstrap_args.push_back("-M");
    pacstrap_args.push_back("--");
    pacstrap_args.push_back(realpath(bp2.airootfs_dir));
    for(String pkgkun:packages){
        pacstrap_args.push_back(pkgkun);
    }
    FascodeUtil::custom_exec_v(pacstrap_args);
    _msg_info("Done! Packages installed successfully.");
}
Vector<String> split_passwd(String src){
    std::stringstream linekun{src};
    std::string buf;
    Vector<String> return_vect;
    while(std::getline(linekun,buf,':')){
        return_vect.push_back(buf);
    }
    return return_vect;
}
void trap_handler(int signo){
    if(signo==SIGTERM || signo == SIGHUP || signo == SIGINT || signo == SIGKILL){
        force_umount();
    }
}
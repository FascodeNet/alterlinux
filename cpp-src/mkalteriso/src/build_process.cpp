#include "build_process.hpp"
template<class T, class U> std::string replace(std::string s, const T& target, const U& replacement, bool replace_first = 0, bool replace_empty = 0) {
  using S = std::string;
  using C = std::string::value_type;
  using N = std::string::size_type;
  struct {
    auto len(const S& s) { return s.size(); }
    auto len(const C* p) { return std::char_traits<C>::length(p); }
    auto len(const C  c) { return 1; }
    auto sub(S* s, const S& t, N pos, N len) { s->replace(pos, len, t); }
    auto sub(S* s, const C* t, N pos, N len) { s->replace(pos, len, t); }
    auto sub(S* s, const C  t, N pos, N len) { s->replace(pos, len, 1, t); }
    auto ins(S* s, const S& t, N pos) { s->insert(pos, t); }
    auto ins(S* s, const C* t, N pos) { s->insert(pos, t); }
    auto ins(S* s, const C  t, N pos) { s->insert(pos, 1, t); }
  } util;
  
  N target_length      = util.len(target);
  N replacement_length = util.len(replacement);
  if (target_length == 0) {
    if (!replace_empty || replacement_length == 0) return s;
    N n = s.size() + replacement_length * (1 + s.size());
    s.reserve(!replace_first ? n: s.size() + replacement_length );
    for (N i = 0; i < n; i += 1 + replacement_length ) {
      util.ins(&s, replacement, i);
      if (replace_first) break;
    }
    return s;
  }
  
  N pos = 0;
  while ((pos = s.find(target, pos)) != std::string::npos) {
    util.sub(&s, replacement, pos, target_length);
    if (replace_first) return s;
    pos += replacement_length;
  }
  return s;
}
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
    _run_once(_make_aur_packages,"_make_aur_packages");
    _run_once(_make_customize_airootfs,"_make_customize_airootfs");
    _run_once(_make_pkglist,"_make_pkglist");
    _make_boot();
    _run_once(_cleanup,"_cleanup");
    _run_once(_make_prepare,"_make_prepare");
    _run_once(_make_iso,"_make_iso");
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
        exit(-8);
    }
}
void _make_aur_packages(){
    _msg_info("Installinh aur packages...");
    Vector<String> cp_pacman_conf_args;
    cp_pacman_conf_args.push_back("cp");
    cp_pacman_conf_args.push_back("-f");
    cp_pacman_conf_args.push_back(realpath(bp2.work_dir + "/pacman.conf"));
    cp_pacman_conf_args.push_back(bp2.airootfs_dir + "/etc/alteriso-pacman.conf");
    FascodeUtil::custom_exec_v(cp_pacman_conf_args);
    Vector<String> cp_aur_sh;
    cp_aur_sh.push_back("cp");
    cp_aur_sh.push_back("-rf");
    cp_aur_sh.push_back("--preserve=mode");
    cp_aur_sh.push_back(realpath("archiso/aur.sh"));
    cp_aur_sh.push_back(bp2.airootfs_dir + "/root/aur.sh");
    FascodeUtil::custom_exec_v(cp_aur_sh);
    Vector<String> aurkun;
    aurkun.push_back("/root/aur.sh");
    
    for(String pkgk:bp2.aur_packages_vector){
        aurkun.push_back(pkgk);
    }
    Vector<String> chmodkun;
    chmodkun.push_back("chmod");
    chmodkun.push_back("-f");
    chmodkun.push_back("+x");
    chmodkun.push_back(bp2.airootfs_dir + "/root/aur.sh");
    FascodeUtil::custom_exec_v(chmodkun);
    run_cmd_on_chroot(aurkun);
    Vector<String> rmdirkun;
    rmdirkun.push_back("rm");
    rmdirkun.push_back("-rf");
    rmdirkun.push_back(bp2.airootfs_dir + "/root/aur.sh");
    if(dir_exist(bp2.airootfs_dir + "/root/aur.sh")){
        FascodeUtil::custom_exec_v(rmdirkun);
    }
    
    _msg_info("Done!");
}

void run_cmd_on_chroot(Vector<String> commands){
    Vector<String> arch_chroot_args;
    arch_chroot_args.push_back("arch-chroot");
    arch_chroot_args.push_back(realpath(bp2.airootfs_dir));
    for(String arg:commands){
        arch_chroot_args.push_back(arg);
    }
    FascodeUtil::custom_exec_v(arch_chroot_args);
}
void _make_customize_airootfs(){
    if(dir_exist(bp2.profile + "/airootfs/etc/passwd")) {
        _msg_info("Copying /etc/skel/* to user homes...");

        std::ifstream passwd_stream(realpath(bp2.profile + "/airootfs/etc/passwd"));
        if(!passwd_stream.is_open()){
            _msg_error("Can't open " + realpath(bp2.profile + "/airootfs/etc/passwd"));
            return;
        }
        String line;
        while(getline(passwd_stream,line)){
            Vector<String> passwd=split_passwd(line);
            if(std::atoi(passwd.at(2).c_str()) >= 1000 && std::atoi(passwd.at(2).c_str()) < 60000) continue;
            if(passwd.at(5) == "/" || passwd.at(5) == "") continue;
            Vector<String> cp_args;
            cp_args.push_back("cp");
            cp_args.push_back("-dnRT");
            cp_args.push_back("--preserve=mode,timestamps,links");
            cp_args.push_back("--");
            cp_args.push_back(bp2.airootfs_dir + "/etc/skel");
            cp_args.push_back(bp2.airootfs_dir + passwd.at(5));
            FascodeUtil::custom_exec_v(cp_args);
            Vector<String> chmod_args;
            chmod_args.push_back("chmod");
            chmod_args.push_back("-f");
            chmod_args.push_back("0750");
            chmod_args.push_back("--");
            chmod_args.push_back(bp2.airootfs_dir + passwd.at(5));
            FascodeUtil::custom_exec_v(chmod_args);
            Vector<String> chown_args;
            chown_args.push_back("chown");
            chown_args.push_back("-hR");
            chown_args.push_back("--");
            chown_args.push_back(passwd.at(2) + ":" + passwd.at(3));
            chown_args.push_back(bp2.airootfs_dir + passwd.at(5));
            FascodeUtil::custom_exec_v(chown_args);
        }
        _msg_info("Done!");
    }
    if(dir_exist(bp2.airootfs_dir + "/root/customize_airootfs.sh")){
        _msg_info("Running customize_airootfs.sh in " + realpath(bp2.airootfs_dir + "/root/customize_airootfs.sh") + "chroot...");
        Vector<String> run_cmdS;
        run_cmdS.push_back("/root/customize_airootfs.sh");
        run_cmd_on_chroot(run_cmdS);
        Vector<String> run_rmdir;
        run_rmdir.push_back("rm");
        run_rmdir.push_back("--");
        run_rmdir.push_back(bp2.airootfs_dir + "/root/customize_airootfs.sh");
        FascodeUtil::custom_exec_v(run_rmdir);
        _msg_info("Done! customize_airootfs.sh run successfully.");
    }
}
void _make_pkglist(){
    Vector<String> install_args;
    install_args.push_back("install");
    install_args.push_back("-d");
    install_args.push_back("-m");
    install_args.push_back("0755");
    install_args.push_back("--");
    install_args.push_back(bp2.isofs_dir + "/" + bp2.install_dir);
    FascodeUtil::custom_exec_v(install_args);
    _msg_info("Creating a list of installed packages on live-enviroment...");
    Vector<String> bash_args;
    bash_args.push_back("bash");
    bash_args.push_back("-c");
    bash_args.push_back("pacman -Q --sysroot \"" + bp2.airootfs_dir + "\" > \"" + bp2.isofs_dir + "/" + bp2.install_dir + "/pkglist." + bp2.arch + ".txt\"");
    FascodeUtil::custom_exec_v(bash_args);
    _msg_info("Done!");
}
void _make_boot(){
    _make_boot_on_iso();
    _make_boot_efi();
}
void _make_boot_efi(){
    _make_boot_efi_esp();
    _make_efi();
}
void _make_efi(){
    _msg_info("Preparing an /EFI directory for the ISO 9660 file system...");
    Vector<String> Install_1_args;
    Install_1_args.push_back("install");
    Install_1_args.push_back("-d");
    Install_1_args.push_back("-m");
    Install_1_args.push_back("0755");
    Install_1_args.push_back("--");
    Install_1_args.push_back(bp2.isofs_dir + "/EFI/BOOT");
    FascodeUtil::custom_exec_v(Install_1_args);
    Vector<String> Install_2_args;
    Install_2_args.push_back("install");
    Install_2_args.push_back("-m");
    Install_2_args.push_back("0644");
    Install_2_args.push_back("--");
    Install_2_args.push_back(bp2.airootfs_dir + "/usr/lib/systemd/boot/efi/systemd-bootx64.efi");
    Install_2_args.push_back(bp2.isofs_dir + "/EFI/BOOT/BOOTx64.EFI");
    FascodeUtil::custom_exec_v(Install_2_args);
    Vector<String> Install_3_args;
    Install_3_args.push_back("install");
    Install_3_args.push_back("-d");
    Install_3_args.push_back("-m");
    Install_3_args.push_back("0755");
    Install_3_args.push_back("--");
    Install_3_args.push_back(bp2.isofs_dir + "/loader/entries");
    FascodeUtil::custom_exec_v(Install_3_args);
    Vector<String> Install_4_args;
    Install_4_args.push_back("install");
    Install_4_args.push_back("-m");
    Install_4_args.push_back("0644");
    Install_4_args.push_back("--");
    Install_4_args.push_back(bp2.profile + "/efiboot/loader/loader.conf");
    Install_4_args.push_back(bp2.isofs_dir + "/loader/");

    for(const std::filesystem::directory_entry &i:std::filesystem::directory_iterator(bp2.profile + "/efiboot/loader/entries/")){
        std::ifstream ifs(i.path().string());
        String buf_path= bp2.isofs_dir + "/loader/entries/" + i.path().filename().string();
        std::ofstream ofs(buf_path);
        std::string buf;
        while (getline(ifs, buf)) {
            String dest_str=replace(replace(replace(buf,"%ARCHISO_LABEL%",bp2.iso_label),"%INSTALL_DIR%",bp2.install_dir),"%ARCH%",bp2.arch);
            ofs << dest_str << "\n";
        }
        ifs.close();
        ofs.close();
    }
    if(dir_exist(bp2.airootfs_dir + "/usr/share/edk2-shell/x64/Shell_Full.efi")){
        Vector<String> install_argskun;
        install_argskun.push_back("install");
        install_argskun.push_back("-m");
        install_argskun.push_back("0644");
        install_argskun.push_back("--");
        install_argskun.push_back(bp2.airootfs_dir + "/usr/share/edk2-shell/x64/Shell_Full.efi");
        install_argskun.push_back(bp2.isofs_dir + "/shellx64.efi");
        FascodeUtil::custom_exec_v(install_argskun);
    }
    _msg_info("Done!");

}   
void _make_boot_efi_esp(){
    String img_path=bp2.work_dir + "/efiboot.img";
    if(dir_exist(img_path)){
        rmdir(img_path.c_str());
    }
    long img_kb=1024*1024;
    _msg_info("Creating FAT image of size: " + std::to_string(img_kb) + "Kib...");
    Vector<String> mkfs_fat_args;
    mkfs_fat_args.push_back("mkfs.fat");
    mkfs_fat_args.push_back("-C");
    mkfs_fat_args.push_back("-n");
    mkfs_fat_args.push_back("ARCHISO_EFI");
    mkfs_fat_args.push_back(img_path);
    mkfs_fat_args.push_back(std::to_string(img_kb));
    FascodeUtil::custom_exec_v(mkfs_fat_args);
    Vector<String> mmd_1_args;
    mmd_1_args.push_back("mmd");
    mmd_1_args.push_back("-i");
    mmd_1_args.push_back(img_path);
    mmd_1_args.push_back("::/EFI");
    mmd_1_args.push_back("::/EFI/BOOT");
    FascodeUtil::custom_exec_v(mmd_1_args);
    Vector<String> mcopy_1_args;
    mcopy_1_args.push_back("mcopy");
    mcopy_1_args.push_back("-i");
    mcopy_1_args.push_back(img_path);
    mcopy_1_args.push_back(bp2.airootfs_dir + "/usr/lib/systemd/boot/efi/systemd-bootx64.efi");
    mcopy_1_args.push_back("::/EFI/BOOT/BOOTx64.EFI") ;
    FascodeUtil::custom_exec_v(mcopy_1_args);

    Vector<String> mmd_2_args;
    mmd_2_args.push_back("mmd");
    mmd_2_args.push_back("-i");
    mmd_2_args.push_back(img_path);
    mmd_2_args.push_back("::/loader");
    mmd_2_args.push_back("::/loader/entries");
    FascodeUtil::custom_exec_v(mmd_2_args);

    Vector<String> mcopy_2_args;
    mcopy_2_args.push_back("mcopy");
    mcopy_2_args.push_back("-i");
    mcopy_2_args.push_back(img_path);
    mcopy_2_args.push_back(bp2.profile + "/efiboot/loader/loader.conf");
    mcopy_2_args.push_back("::/loader/") ;
    FascodeUtil::custom_exec_v(mcopy_2_args);
    for(const std::filesystem::directory_entry &i:std::filesystem::directory_iterator(bp2.profile + "/efiboot/loader/entries/")){
        std::ifstream ifs(i.path().string());
        String buf_path= bp2.work_dir + "/entries_tmp";
        std::ofstream ofs(buf_path);
        std::string buf;
        while (getline(ifs, buf)) {
            String dest_str=replace(replace(replace(buf,"%ARCHISO_LABEL%",bp2.iso_label),"%INSTALL_DIR%",bp2.install_dir),"%ARCH%",bp2.arch);
            ofs << dest_str << "\n";
        }
        ifs.close();
        ofs.close();
        Vector<String> mcopykun_args;
        mcopykun_args.push_back("mcopy");
        mcopykun_args.push_back("-i");
        mcopykun_args.push_back(img_path);
        mcopykun_args.push_back(buf_path);
        mcopykun_args.push_back("::/loader/entries/" + i.path().filename().string());
        FascodeUtil::custom_exec_v(mcopykun_args);
        rmdir(buf_path.c_str());
    }
    if(dir_exist(bp2.airootfs_dir + "/usr/share/edk2-shell/x64/Shell_Full.efi")){
        Vector<String> mcopy_shell;
        mcopy_shell.push_back("mcopy");
        mcopy_shell.push_back("-i");
        mcopy_shell.push_back(img_path);
        mcopy_shell.push_back(bp2.airootfs_dir + "/usr/share/edk2-shell/x64/Shell_Full.efi");
        mcopy_shell.push_back("::/shellx64.efi");
        FascodeUtil::custom_exec_v(mcopy_shell);
    }
    _make_boot_on_fat();
    _msg_info("Done! systemd-boot set up for UEFI booting successfully.");
}
void _make_boot_on_fat(){
    _msg_info("Preparing kernel and intramfs for the FAT file system...");
    String img_path=bp2.work_dir + "/efiboot.img";
    Vector<String> mmd_args;
    mmd_args.push_back("mmd");
    mmd_args.push_back("-i");
    mmd_args.push_back(img_path);
    mmd_args.push_back("::/" + bp2.install_dir);
    mmd_args.push_back("::/" + bp2.install_dir + "/boot");
    mmd_args.push_back("::/" + bp2.install_dir + "/boot/" + bp2.arch);
    FascodeUtil::custom_exec_v(mmd_args);
    Vector<String> mcopy_bash;
    mcopy_bash.push_back("bash");
    mcopy_bash.push_back("-c");
    mcopy_bash.push_back("mcopy -i \"" + img_path + "\" \"" + bp2.airootfs_dir + "/boot/vmlinuz-\"* \"" + bp2.airootfs_dir + 
    "/boot/initramfs-\"*\".img\" \"::/" + bp2.install_dir + "/boot/" + bp2.arch + "/\"");
    FascodeUtil::custom_exec_v(mcopy_bash);
    Vector<String> all_ucode_images;
    Vector<String> ucode_imageskun={"intel-uc.img","intel-ucode.img","amd-uc.img","amd-ucode.img","early_ucode.cpio","microcode.cpio"};
    for(String ucode_img : ucode_imageskun){
        if(dir_exist(bp2.airootfs_dir + "/boot/" + ucode_img)){
            all_ucode_images.push_back(bp2.airootfs_dir + "/boot/" + ucode_img);
        }
    }
    if(all_ucode_images.size() > 0){
        Vector<String> mcopy_args;
        mcopy_args.push_back("mcopy");
        mcopy_args.push_back("-i");
        mcopy_args.push_back(img_path);
        for(String imgkun:all_ucode_images){
            mcopy_args.push_back(imgkun);
        }
        mcopy_args.push_back("::/" + bp2.install_dir + "/boot/");
        FascodeUtil::custom_exec_v(mcopy_args);
    }
    _msg_info("Done!");

}
void _make_boot_on_iso(){

    Vector<String> install_mkdir;
    install_mkdir.push_back("install");
    install_mkdir.push_back("-d");
    install_mkdir.push_back("-m");
    install_mkdir.push_back("0755");
    install_mkdir.push_back("--");
    install_mkdir.push_back(bp2.isofs_dir +  "/" + bp2.install_dir +  "/boot/" + bp2.arch);
    FascodeUtil::custom_exec_v(install_mkdir);
    Vector<String> install_bash;
    install_bash.push_back("bash");
    install_bash.push_back("-c");
    install_bash.push_back("install -m 0644 -- \"" + bp2.airootfs_dir + "/boot/vmlinuz-\"* \"" + bp2.isofs_dir + "/" + bp2.install_dir + "/boot/" + bp2.arch + "/\"");
    FascodeUtil::custom_exec_v(install_bash);    
    Vector<String> install_bash2;
    install_bash2.push_back("bash");
    install_bash2.push_back("-c");
    install_bash2.push_back("install -m 0644 -- \"" + bp2.airootfs_dir + "/boot/initramfs-\"*\".img\" \"" + bp2.isofs_dir + "/" + bp2.install_dir + "/boot/" + bp2.arch + "/\"");
    FascodeUtil::custom_exec_v(install_bash2);
    Vector<String> all_ucode_images;
    Vector<String> ucode_imageskun={"intel-uc.img","intel-ucode.img","amd-uc.img","amd-ucode.img","early_ucode.cpio","microcode.cpio"};
    for(String ucode_img : ucode_imageskun){
        if(dir_exist(bp2.airootfs_dir + "/boot/" + ucode_img)){
            all_ucode_images.push_back(bp2.airootfs_dir + "/boot/" + ucode_img);
        }
    }
    if(all_ucode_images.size() > 0){
        for(String imgkun:all_ucode_images){
            Vector<String> install_args;
            install_args.push_back("install");
            install_args.push_back("-m");
            install_args.push_back("0644");
            install_args.push_back("--");
            install_args.push_back(imgkun);
            install_args.push_back(bp2.isofs_dir + "/" + bp2.install_dir + "/boot/");
            FascodeUtil::custom_exec_v(install_args);
        }
    }
    _msg_info("Done!");
}
void _cleanup(){
    _msg_info("Cleaning up what we can on airootfs...");
    if(dir_exist(bp2.airootfs_dir + "/boot")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/boot");
        find_args.push_back("-mindepth");
        find_args.push_back("1");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    if(dir_exist(bp2.airootfs_dir + "/var/lib/pacman")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/var/lib/pacman");
        find_args.push_back("-maxdepth");
        find_args.push_back("1");
        find_args.push_back("-type");
        find_args.push_back("f");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    if(dir_exist(bp2.airootfs_dir + "/var/lib/pacman/sync")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/var/lib/pacman/sync");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    if(dir_exist(bp2.airootfs_dir + "/var/cache/pacman/pkg")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/var/cache/pacman/pkg");
        find_args.push_back("-type");
        find_args.push_back("f");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    if(dir_exist(bp2.airootfs_dir + "/var/log")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/var/log");
        find_args.push_back("-type");
        find_args.push_back("f");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    if(dir_exist(bp2.airootfs_dir + "/var/tmp")){
        Vector<String> find_args;
        find_args.push_back("find");
        find_args.push_back(bp2.airootfs_dir + "/var/tmp");
        find_args.push_back("-mindepth");
        find_args.push_back("1");
        find_args.push_back("-delete");
        FascodeUtil::custom_exec_v(find_args);
    }
    // Delete package pacman related files.
    Vector<String> find_pkg_args;
    find_pkg_args.push_back("find");
    find_pkg_args.push_back(bp2.work_dir);
    find_pkg_args.push_back("(");
    find_pkg_args.push_back("-name");
    find_pkg_args.push_back("*.pacnew");
    find_pkg_args.push_back("-o");
    find_pkg_args.push_back("-name");
    find_pkg_args.push_back("*.pacsave");
    find_pkg_args.push_back("-o");
    find_pkg_args.push_back("-name");
    find_pkg_args.push_back("*.pacorig");
    find_pkg_args.push_back(")");
    find_pkg_args.push_back("-delete");
    FascodeUtil::custom_exec_v(find_pkg_args);
    std::ofstream ofkuns(bp2.airootfs_dir + "/etc/machine-id",std::ios_base::out | std::ios_base::trunc);
    ofkuns.close();
    _msg_info("Done!");
}
void _make_prepare(){
    _run_once(_mkairootfs_img,"_mkairootfs_img");
    _mkchecksum();
}
void _mkairootfs_img(){
    if(!dir_exist(bp2.airootfs_dir)){
        _msg_error("NOT FOUND airootfs!");
        force_umount();
        _exit(-910);
    }
    force_umount();
    Vector<String> install_iso_dir;
    install_iso_dir.push_back("install");
    install_iso_dir.push_back("-d");
    install_iso_dir.push_back("-m");
    install_iso_dir.push_back("0755");
    install_iso_dir.push_back("--");
    install_iso_dir.push_back(bp2.isofs_dir + "/" + bp2.install_dir + "/" + bp2.arch);
    FascodeUtil::custom_exec_v(install_iso_dir);
    _msg_info("Creating SquashFS image, this may take some time...");
    _mkairootfs_create_image(realpath(bp2.work_dir) + "/airootfs.img");
    _msg_info("Done!");
    Vector<String> rmdir_args;
    rmdir_args.push_back("rm");
    rmdir_args.push_back("--");
    rmdir_args.push_back(realpath(bp2.work_dir) + "/airootfs.img");
    FascodeUtil::custom_exec_v(rmdir_args);

}

void sha256_hash_string (unsigned char hash[SHA256_DIGEST_LENGTH], char outputBuffer[65])
{
    int i = 0;

    for(i = 0; i < SHA256_DIGEST_LENGTH; i++)
    {
        sprintf(outputBuffer + (i * 2), "%02x", hash[i]);
    }

    outputBuffer[64] = 0;
}

int sha256_file(String path, char outputBuffer[65])
{
    FILE *file = fopen(path.c_str(), "rb");
    if(!file) return -534;

    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    const int bufSize = 32768;
    unsigned char *buffer = (unsigned char*)malloc(bufSize);
    int bytesRead = 0;
    if(!buffer) return ENOMEM;
    while((bytesRead = fread(buffer, 1, bufSize, file)))
    {
        SHA256_Update(&sha256, buffer, bytesRead);
    }
    SHA256_Final(hash, &sha256);

    sha256_hash_string(hash, outputBuffer);
    fclose(file);
    free(buffer);
    return 0;
}
void _mkairootfs_create_image(String src_name){
    String image_path=bp2.isofs_dir + "/" + bp2.install_dir + "/" + bp2.arch + "/airootfs.sfs";
    Vector<String> mksquashfs_args;
    mksquashfs_args.push_back("mksquashfs");
    mksquashfs_args.push_back(src_name);
    mksquashfs_args.push_back(image_path);
    mksquashfs_args.push_back("-noappend");
    for(String optkun:bp2.airootfs_image_tool_options){
        mksquashfs_args.push_back(optkun);
    }
    for(String laaa:mksquashfs_args){
        std::cout << laaa << " ";
    }
    std::cout << std::endl;
    FascodeUtil::custom_exec_v(mksquashfs_args);
    
}
void _mkchecksum(){
    _msg_info("Creating checksum file for self-test...");
    char buffer[65];
    sha256_file(bp2.isofs_dir + "/" + bp2.install_dir + "/" + bp2.arch + "/airootfs.sfs",buffer);
    std::ofstream outkun(bp2.isofs_dir + "/" + bp2.install_dir + "/" + bp2.arch + "/airootfs.sha256");
    outkun << buffer;
    outkun.close();
    _msg_info("Done!");
}
void _make_iso(){
    Vector<String> xorrisofs_options;
    if(!dir_exist(bp2.out_dir)) mkdir(bp2.out_dir.c_str(),644);
    /*if(std::find(bp2.bootmodes.begin(),bp2.bootmodes.end(),"uefi-x64") != bp2.bootmodes.end()){
        _msg_debug("Found EFI!");

    }*/
    if(!dir_exist(bp2.work_dir + "/efiboot.img")){
        _msg_error("The file " + bp2.work_dir + "/efiboot.img' does not exist.");
        exit_force(8);
        exit(88);
    }
    if(dir_exist(bp2.isofs_dir + "/EFI/archiso" )){
        Vector<String> rm_args;
        rm_args.push_back("rm");
        rm_args.push_back("-rf");
        rm_args.push_back("--");
        rm_args.push_back(bp2.isofs_dir + "/EFI/archiso");
        FascodeUtil::custom_exec_v(rm_args);
    }
    //for EFI USB?
    xorrisofs_options.push_back("-partition_offset");
    xorrisofs_options.push_back("16");
    xorrisofs_options.push_back("-append_partition");
    xorrisofs_options.push_back("2");
    xorrisofs_options.push_back("C12A7328-F81F-11D2-BA4B-00A0C93EC93B");
    xorrisofs_options.push_back(bp2.work_dir + "/efiboot.img");
    xorrisofs_options.push_back("-appended_part_as_gpt");
    //for EFI CDROM?
    xorrisofs_options.push_back("-eltorito-alt-boot");
    xorrisofs_options.push_back("-e");
    xorrisofs_options.push_back("--interval:appended_partition_2:all::");
    xorrisofs_options.push_back("-no-emul-boot");
    //iso create
    _msg_info("Creating ISO image...");
    Vector<String> xorrisofs_args;
    xorrisofs_args.push_back("xorriso");
    xorrisofs_args.push_back("-as");
    xorrisofs_args.push_back("mkisofs");
    xorrisofs_args.push_back("-iso-level");
    xorrisofs_args.push_back("3");
    xorrisofs_args.push_back("-full-iso9660-filenames");
    xorrisofs_args.push_back("-joliet");
    xorrisofs_args.push_back("-joliet-long");
    xorrisofs_args.push_back("-rational-rock");
    xorrisofs_args.push_back("-volid");
    xorrisofs_args.push_back(bp2.iso_label);
    xorrisofs_args.push_back("-appid");
    xorrisofs_args.push_back(bp2.iso_application);
    xorrisofs_args.push_back("-publisher");
    xorrisofs_args.push_back(bp2.iso_publisher);
    xorrisofs_args.push_back("-preparer");
    xorrisofs_args.push_back("prepared by " + bp2.app_name);
    for(String inkun : xorrisofs_options){
        xorrisofs_args.push_back(inkun);
    }
    xorrisofs_args.push_back("-output");
    xorrisofs_args.push_back(bp2.out_dir + "/" + bp2.img_name);
    xorrisofs_args.push_back(bp2.isofs_dir + "/");
    FascodeUtil::custom_exec_v(xorrisofs_args);
    Vector<String> du_args;
    du_args.push_back("du");
    du_args.push_back("-h");
    du_args.push_back("--");
    du_args.push_back(bp2.out_dir + "/" + bp2.img_name);
    _msg_info("Done!");
    FascodeUtil::custom_exec_v(du_args);

}
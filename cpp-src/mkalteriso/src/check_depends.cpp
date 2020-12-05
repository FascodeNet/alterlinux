#include "check_depends.hpp"
bool check_depends_class::check_depends(){
    enum _alpm_errno_t err;
    
    pmhandle=alpm_initialize("/","/var/lib/pacman",&err);
    Vector<String> repo_list={
        "core",
        "extra",
        "community",
        "multilib",
        "alter-stable"
    };
    for(String repo_name:repo_list){
        alpm_register_syncdb(pmhandle,repo_name.c_str(),2048);
    }
    local_dbkun=alpm_get_localdb(pmhandle);
    sync_dbskun=alpm_get_syncdbs(pmhandle);
    Vector<String> depends_pkglist={
    "alterlinux-keyring",
    "arch-install-scripts",
    "curl",
    "cmake",
    "dosfstools",
    "git",
    "libburn",
    "libisofs",
    "lz4",
    "lzo",
    "make",
    "ninja",
    "squashfs-tools",
    "libisoburn",
    "lynx",
    "xz",
    "zlib",
    "zstd",
    "qt5-base"
    };
    for(String pkgnm : depends_pkglist){
        if(!compare(pkgnm)){
            return false;
        }
    }
    alpm_release(pmhandle);
    return true;
}
alpm_pkg_t* check_depends_class::get_from_localdb(String pkgname){
    return alpm_db_get_pkg(local_dbkun,pkgname.c_str());
}
alpm_pkg_t* check_depends_class::get_from_syncdb(String pkgname){

    Vector<alpm_db_t*> syncdbskun_vect=to_array_dbskun(sync_dbskun);
    for(alpm_db_t* dbkun : syncdbskun_vect){
        _msg_debug(alpm_db_get_name(dbkun));
        alpm_pkg_t* pkgkun=alpm_db_get_pkg(dbkun,pkgname.c_str());
        if(pkgkun != nullptr){
            return pkgkun;
        }
    }
    return nullptr;
}
Vector<alpm_db_t*> check_depends_class::to_array_dbskun(alpm_list_t* databases){
    Vector<alpm_db_t*> return_v_kun;
    to_array_dbskun(databases,&return_v_kun);
    return return_v_kun;
}
void check_depends_class::to_array_dbskun(alpm_list_t* databases,Vector<alpm_db_t*>* vect){
    if(databases->data != nullptr){
        vect->push_back((alpm_db_t*)databases->data);
    }
    if(databases->next != nullptr){
        to_array_dbskun((__alpm_list_t*)databases->next,vect);
    }
}
bool check_depends_class::compare(String pkgname){
    alpm_pkg_t* pkg_local=get_from_localdb(pkgname);
    alpm_pkg_t* pkg_sync=get_from_syncdb(pkgname);
    if(pkg_local == nullptr){
        _msg_error(pkgname + " is not installed.");
        return false;
    }
    if(pkg_sync == nullptr){
        _msg_error("Failed to get the latest version of " + pkgname);
        return true;
    }
    String pkg_ver_local=alpm_pkg_get_version(pkg_local);
    String pkg_ver_sync=alpm_pkg_get_version(pkg_sync);
    if(pkg_ver_local == pkg_ver_sync){
        _msg_info("latest : " + pkgname);
        return true;
    }else{
        return false;
    }
}
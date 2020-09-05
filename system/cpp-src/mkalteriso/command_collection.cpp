#include "command_collection.h"

command_collection::command_collection(QObject *parent) : QObject(parent)
{
umount_kun=false;
}
void command_collection::set_build_setting(build_setting* bss){
    bskun=bss;

}
int command_collection::command_init(){
    if(bskun == nullptr) return 569;//NULL POINTER
    _show_config(INIT);
    _chroot_init();
    return 0;
}
int command_collection::command_install(){
    if(bskun == nullptr ) return 444;   //null pointer
    QFileInfo finfo(bskun->get_pacman_conf());
    if(!finfo.exists()){
        _msg_err("Pacman config file '" + bskun->get_pacman_conf() + "' does not exist");
        return 1;
    }
    _show_config(INSTALL);
    QString pkgls=bskun->get_pkg_list();
    pkgls=pkgls.simplified();
    if(pkgls == ""){
        _msg_err("Packages must be specified");
        return 2;
    }
    _pacman(pkgls);
    return 0;

}
int command_collection::command_install_file(){
    if(bskun == nullptr ) return 444;   //null pointer
    QFileInfo finfo(bskun->get_pacman_conf());
    if(!finfo.exists()){
        _msg_err("Pacman config file '" + bskun->get_pacman_conf() + "' does not exist");
        return 1;
    }
    _show_config(INSTALL);
    QString pkgls=bskun->get_pkg_list();
    pkgls=pkgls.simplified();
    if(pkgls == ""){
        _msg_err("Packages must be specified");
        return 2;
    }
    _pacman_file(pkgls);
    return 0;

}
int command_collection::_chroot_init(){
    if(bskun==nullptr)return 777;   // nullptr
    QDir dir(bskun->get_work_dir());
    if(!dir.exists("airootfs")){
        dir.mkpath("airootfs");
    }
    if(bskun->get_wsl()){

        _pacman("base base-devel git");
    }
    else {
        _pacman("base base-devel syslinux mkinitcpio git");
    }
    return 0;
}
int command_collection::command_run(){
    if(bskun == nullptr) return 456;//nullptr
    if(bskun->get_run_cmd() == ""){
        _msg_err("Not found command....\nYou must set command!");
        return 3;
    }
    _show_config(RUN);
    return _chroot_run();

}
int command_collection::command_tarball(QString tarfile_name){

    QDir Outdir(bskun->get_out_dir());
    if(!Outdir.exists()){
        Outdir.cdUp();
        Outdir.mkdir(bskun->get_out_dir());
    }
    _msg_info("Creating tarball...");
    QString _vflag="";
    if(!bskun->get_quiet() || bskun->get_debug_mode()){
        _vflag="v";
    }
    QString tar_filepath=Outdir.path() + "/" + tarfile_name;
    QString tar_cmd="tar Jpcf" + _vflag + " "+ tar_filepath + " " +bskun->get_work_dir() + "/" + bskun->get_architecture() + "/airootfs-tarball/*";
    system(tar_cmd.toUtf8().data());
    _checksum_common(tar_filepath);
    _msg_success("Done! " + tar_filepath);
    return 0;
}
int command_collection::_cleanup(){
    if(bskun == nullptr) return 456;//nullptr
    QDir bootkun(bskun->get_work_dir() + "/airootfs/boot");
    if(bootkun.exists()){   //Delete initcpio image(s) and kernel(s)
        QStringList nameFilters;
        nameFilters.append("*.img");
        nameFilters.append("vmlinuz*");
        QStringList fileskun=bootkun.entryList(nameFilters,QDir::Files);
        for(QString filekun:fileskun){
            bootkun.remove(filekun);
        }
    }
    QDir pacman_sync_D(bskun->get_work_dir() + "/airootfs/var/lib/pacman/sync");
    if(pacman_sync_D.exists()){
        QStringList fileskun=pacman_sync_D.entryList(QDir::Files);
        for(QString filekun:fileskun){
            pacman_sync_D.remove(filekun);
        }
    }
    QDir pacman_sync_C(bskun->get_work_dir() + "/airootfs/var/lib/pacman/pkg");
    if(pacman_sync_C.exists()){
        QStringList fileskun=pacman_sync_C.entryList(QDir::Files);
        for(QString filekun:fileskun){
            pacman_sync_C.remove(filekun);
        }
    }
    QDir pacman_(bskun->get_work_dir() + "/airootfs/var/lib/pacman");
    if(pacman_.exists()){
        QStringList fileskun=pacman_.entryList(QDir::Files);
        for(QString filekun:fileskun){
            pacman_.remove(filekun);
        }
    }
    QDir all_logkun(bskun->get_work_dir() + "/airootfs/var/log");
    if(all_logkun.exists()){
        QStringList fileskun=all_logkun.entryList(QDir::Files);
        for(QString filekun:fileskun){
            all_logkun.remove(filekun);
        }
    }
    QDir all_tmpkun(bskun->get_work_dir() + "/airootfs/var/tmp");
    if(all_tmpkun.exists()){
        QStringList fileskun=all_tmpkun.entryList();
        for(QString filekun:fileskun){
            all_tmpkun.remove(filekun);
        }
    }
    QString cmdkun_buf="work_dir=\"" + bskun->get_work_dir() + "\"\nfind \"${work_dir}\" \\( -name \"*.pacnew\" -o -name \"*.pacsave\" -o -name \"*.pacorig\" \\) -delete";
    _msg_infodbg(cmdkun_buf);
    system(cmdkun_buf.toUtf8().data());
    _msg_success("Done!");
    return 0;
}
int command_collection::_mkairootfs_sfs(){
    if(bskun == nullptr) return 456;//nullptr
    QDir workdirkun(bskun->get_work_dir());
    if(!workdirkun.exists("airootfs")){
        _msg_err("The path '" + bskun->get_work_dir() + "/airootfs' does not exist");
        return 1;
    }
    workdirkun.mkpath("iso/" + bskun->get_install_dir() +"/" + bskun->get_architecture());
    _msg_info("Creating SquashFS image, this may take some time...");
    QString mksquashfs_cmd="mksquashfs \"" +  bskun->get_work_dir() + "/airootfs\" \"" + bskun->get_work_dir() + "/iso/" + bskun->get_install_dir()
            + "/" + bskun->get_architecture() + "/airootfs.sfs\" -noappend -comp \""
            + bskun->get_sfs_comp() + "\" " + bskun->get_sfs_comp_opt();
    _msg_infodbg(mksquashfs_cmd);
    int ret=system(mksquashfs_cmd.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("mksquashfs !\nError code : ") + QString::number(ret) );
        return 2;
    }
    _msg_success("Done!");
    return 0;
}
int command_collection::_mount_airootfs(){
    umount_kun=true;
    QDir workkun(bskun->get_work_dir());
    if(!workkun.exists("mnt/airootfs")){
        workkun.mkpath("mnt/airootfs");
    }
    _msg_info("Mounting '" + bskun->get_work_dir() + "/airootfs.img' on '" + bskun->get_work_dir() + "/mnt/airootfs'");
    QString mount_cmd="mount \"" + bskun->get_work_dir() + "/airootfs.img\" \"" + bskun->get_work_dir() + "/mnt/airootfs\"";    //イメージのマウントコマンドの生成
    _msg_infodbg(mount_cmd);    //デバッグ時のみ表示
    int ret=system(mount_cmd.toUtf8().data());  //実行
    if(ret != 0){   //エラー時
        _msg_err(QString("mount airootfs\nError code : ") + QString::number(ret));
        return 2;
    }

    _msg_success("Done!");
    return 0;

}
void command_collection::_umount_airootfs(){
    _msg_info("Unmounting '" + bskun->get_work_dir() + "/mnt/airootfs'");
    QString umount_cmdrun="umount -d \"" + bskun->get_work_dir() + "/mnt/airootfs\"";
    _msg_info(umount_cmdrun);
    system(umount_cmdrun.toUtf8().data());
    _msg_success("Done!");
    QString rmdirkun="rmdir \"" + bskun->get_work_dir() + "/mnt/airootfs\"";
    _msg_info(rmdirkun);
    system(rmdirkun.toUtf8().data());

}
void command_collection::force_umount(){
    if(umount_kun){
        _umount_airootfs();
    }
}
int command_collection::_mkairootfs_img(){
    int ret;
    QDir workdirkun(bskun->get_work_dir());
    if(!workdirkun.exists("airootfs")){
        _msg_err("The path '" + bskun->get_work_dir() + "/airootfs' does not exist");
        return 1;
    }
    _msg_info("Creating ext4 image of 32GiB...");
    QString truncate_cmdstr="truncate -s 32GB \"" + bskun->get_work_dir() + "/airootfs.img\"";
    _msg_infodbg(truncate_cmdstr);
    ret = system(truncate_cmdstr.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("truncate ! \nError code : ") + QString::number(ret));
        return 4;
    }
    QString mkfs_ext4_cmdstr="mkfs.ext4 -O ^has_journal,^resize_inode -E lazy_itable_init=0 -m 0 -F \"" + bskun->get_work_dir() + "/airootfs.img\"";
    _msg_infodbg(mkfs_ext4_cmdstr);
    ret=system(mkfs_ext4_cmdstr.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("mkfs.ext4 ! \nError code : ") + QString::number(ret));
        return 5;
    }
    QString tune2fs_cmdstr="tune2fs -c 0 -i 0 \"" + bskun->get_work_dir() + "/airootfs.img\"";
    _msg_infodbg(tune2fs_cmdstr);
    ret=system(tune2fs_cmdstr.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("tune2fs ! \nError code : ") + QString::number(ret));
        return 5;
    }
    _msg_success("Done!");
    ret=_mount_airootfs();
    if(ret != 0){
        return ret;
    }
    QString workdirstr=bskun->get_work_dir();
    _msg_info("Copying '" + workdirstr + "/airootfs/' to '" + workdirstr + "/mnt/airootfs/'...");
    QString cp_kun="cp -aT \"" + workdirstr + "/airootfs/\" \"" + workdirstr + "/mnt/airootfs/\"";
    _msg_infodbg(cp_kun);
    ret=system(cp_kun.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("cp ! \nError code : ") + QString::number(ret));
        return 6;
    }
    QString chownkun="chown root:root \"" + workdirstr + "/mnt/airootfs/\"";
    _msg_infodbg(chownkun);
    ret=system(chownkun.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("chown ! \nError code : ") + QString::number(ret));
        return 7;
    }
    _msg_success("Done!");
    _umount_airootfs();
    workdirkun.mkpath("iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture());
    _msg_info("Creating SquashFS image, this may take some time...");
    QString mksquashfskun="mksquashfs \"" + workdirstr + "/airootfs.img\" \"" + workdirstr + "/iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture()
            + "/airootfs.sfs\" -noappend -comp \"" + bskun->get_sfs_comp() + "\" " + bskun->get_sfs_comp_opt();
    _msg_infodbg(mksquashfskun);
    ret=system(mksquashfskun.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("mksquashfs ! \nError code : ") + QString::number(ret));
        workdirkun.remove("airootfs.img");
        return 6;
    }
    _msg_success("Done!");
    workdirkun.remove("airootfs.img");
    return 0;

}
int command_collection::command_prepare(){
    if(bskun == nullptr) return 456;//nullptr
    _show_config(PREPARE);
    _cleanup();
    if(bskun->get_sfs_mode() == "sfs"){
        if(_mkairootfs_sfs()!=0){
            return 2;
        }
    }else{
        if(_mkairootfs_img()!=0){
            return 3;
        }
    }
    _mkchecksum();
    return 0;
}
void command_collection::_mksignature(){
    _msg_info("Creating signature file...");
    QString gpg_cmdkun="cd \"" + bskun->get_work_dir() + "/iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture()
            + "\"\ngpg --detach-sign --default-key " + bskun->get_gpg_key() + "airootfs.sfs";
    _msg_infodbg(gpg_cmdkun);
    system(gpg_cmdkun.toUtf8().data());
    _msg_success("Done!");
}
void command_collection::_mkchecksum(){
    _msg_info("Creating checksum file for self-test...");
    QString sha512sum_cmdkun="cd \"" + bskun->get_work_dir() + "/iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture()
            + "\"\nsha512sum airootfs.sfs > airootfs.sha512";
    _msg_infodbg(sha512sum_cmdkun);
    system(sha512sum_cmdkun.toUtf8().data());
    if(bskun->get_use_gpg_key()){
        _mksignature();
    }
    _msg_success("Done!");
}
int command_collection::command_pkglist(){
    if(bskun == nullptr) return 456;//nullptr
    _msg_info("Creating a list of installed packages on live-enviroment...");
    QString pacman_cmdkun="work_dir=\"" + bskun->get_work_dir() + "\"\ninstall_dir=\"" + bskun->get_install_dir() + "\"\narch=\""
            +bskun->get_architecture() + "\"\npacman -Q --sysroot \"${work_dir}/airootfs\" > \"${work_dir}/iso/${install_dir}/pkglist.${arch}.txt\"";
    _msg_infodbg(pacman_cmdkun);
    system(pacman_cmdkun.toUtf8().data());
    _msg_success("Done!");
    return 0;
}
int command_collection::_chroot_run(){
    QString workdir_safe=bskun->get_work_dir();
    workdir_safe=workdir_safe.replace(";","");
    QString command_strkun="arch-chroot " + workdir_safe + "/airootfs " + bskun->get_run_cmd() ;
    _msg_infodbg(command_strkun);
    system(command_strkun.toUtf8().data());
    return 0;
}
int command_collection::_pacman(QString packages){
    _msg_info("Installing packages to '" + bskun->get_work_dir() + "/airootfs/'...");
    packages=packages.replace(";","");
    QString safe_pacman_conf=bskun->get_pacman_conf();
    safe_pacman_conf=safe_pacman_conf.replace(";","");
    QString safe_workdir=bskun->get_work_dir();
    safe_workdir=safe_workdir.replace(";","");
    QString command_strkun="pacstrap -C \"" + safe_pacman_conf +"\" -c -G -M \"" +safe_workdir + "/airootfs\" " + packages;
    std::wcout << "Running pacstrap......\n" << command_strkun.toStdWString() << std::endl;
    system(command_strkun.toUtf8().data());
    _msg_success("Packages installed successfully!");
    return 0;
}int command_collection::_pacman_file(QString package_path){
    _msg_info("Installing packages to '" + bskun->get_work_dir() + "/airootfs/'...");
    QString safe_pacman_conf=bskun->get_pacman_conf();
    safe_pacman_conf=safe_pacman_conf.replace(";","");
    QString safe_workdir=bskun->get_work_dir();
    safe_workdir=safe_workdir.replace(";","");
    QString command_strkun="pacstrap -C \"" + safe_pacman_conf +"\" -c -G -M -U \"" +safe_workdir + "/airootfs\" " + package_path;
    std::wcout << "Running pacstrap......\n" << command_strkun.toStdWString() << std::endl;
    system(command_strkun.toUtf8().data());
    _msg_success("Packages installed successfully!");
    return 0;
}
template<class... SHOWVALKUN> void command_collection::show_conf_l(int maxkun,void (*do_msgshow)(QString),SHOWVALKUN... txtargkun){
    QString bfkun="";
    for(show_valkun i:std::initializer_list<show_valkun>{txtargkun...}){
        bfkun="";
        bfkun=i.first.rightJustified(maxkun,' ');
        do_msgshow(bfkun + QString("\t") + i.second);
    }
}

template<class... SHOWVALKUN> void command_collection::show_conf_l(void (*do_msgshow)(QString),SHOWVALKUN... txtargkun){
    QString bfkun="";
    int maxkun=0;
    maxkun=max_lenkun_QString(txtargkun...);
    for(show_valkun i:std::initializer_list<show_valkun>{txtargkun...}){
        bfkun="";
        bfkun=i.first.rightJustified(maxkun,' ');
        do_msgshow(bfkun + QString("\t") + i.second);
    }
}
template<class... LNKUN> int command_collection::max_lenkun(LNKUN... args){
    int dest=0;
    for(int i:std::initializer_list<int>{args...}){
        if(dest < i) dest=i;
    }
    return dest;
}
template<class... LNKUNS> int command_collection::max_lenkun_QString(LNKUNS... args){
    int dest=0;
    for(show_valkun sk:std::initializer_list<show_valkun>{args...}){
        if(dest < sk.first.length()) dest=sk.first.length();
    }
    return dest;
}
template<class... SHOWVALKUN> void command_collection::show_conf_dkun(void (*do_msgshow)(QString),SHOWVALKUN... argkun){

    QString command_h="Command:";
    QString Archi_h="Architecture:";
    QString WD_H="Working directory:";
    QString Installe_h="Installation directory:";
    show_valkun command_hkun,arch_hlkun,wd_hkun,inst_hkun;
    command_hkun.first=command_h;
    command_hkun.second=bskun->get_command_args().at(0);
    arch_hlkun.first=Archi_h;
    arch_hlkun.second=bskun->get_architecture();
    wd_hkun.first=WD_H;
    wd_hkun.second=bskun->get_work_dir();
    inst_hkun.first=Installe_h;
    inst_hkun.second=bskun->get_install_dir();
    show_conf_l(do_msgshow,command_hkun,arch_hlkun,wd_hkun,inst_hkun,argkun...);
}
void command_collection::_show_config(show_config_type typekun){
    _msg_info("Configuration settings");
    /*_msg_info("                  Command:\t" + bskun->get_command_args().at(0));
    _msg_info("             Architecture:\t" + bskun->get_architecture());
    _msg_info("        Working directory:\t" + bskun->get_work_dir());
    _msg_info("   Installation directory:\t" + bskun->get_install_dir());
    */

    show_valkun packun_v;
    show_valkun pkg_cfkun;
    show_valkun pkg_cfkun1;
    show_valkun pkg_cfkun2;

    switch(typekun){
    case INIT:
        //_msg_info("       Pacman config file:\t" + bskun->get_pacman_conf());

        packun_v.first="Pacman config file:";
        packun_v.second=bskun->get_pacman_conf();
        show_conf_dkun(_msg_info,packun_v);
        break;
    case INSTALL:
        //_msg_info("       Pacman config file:\t" + bskun->get_pacman_conf());

        packun_v.first="Pacman config file:";
        packun_v.second=bskun->get_pacman_conf();
        pkg_cfkun.first="Packages:";
        pkg_cfkun.second=bskun->get_pkg_list();
        //_msg_info("                 Packages:\t" + bskun->get_pkg_list());
        show_conf_dkun(_msg_info,packun_v,pkg_cfkun);
        break;
    case RUN:
        //_msg_info("              Run command:\t" + bskun->get_run_cmd());
        packun_v.first="Run command:";
        packun_v.second= bskun->get_run_cmd();
        show_conf_dkun(_msg_info,packun_v);
        break;
    case PREPARE:
        //_msg_info("SquashFS compression type:\t" + bskun->get_sfs_comp());
        packun_v.first="SquashFS compression type:";
        packun_v.second=bskun->get_sfs_comp();
        if(bskun->get_sfs_comp_opt() != ""){
            //_msg_info("Squashfs compression opts:\t" + bskun->get_sfs_comp_opt());
            pkg_cfkun.first="Squashfs compression opts:";
            pkg_cfkun.second=bskun->get_sfs_comp_opt();
            show_conf_dkun(_msg_info,packun_v,pkg_cfkun);
        }else{
            show_conf_dkun(_msg_info,packun_v);
        }
        break;
    case ISO:
        //_msg_info("               Image name:\t" + img_name);
        packun_v.first="Image name:";
        packun_v.second=img_name;
        //_msg_info("               Disk label:\t" + bskun->get_iso_label());
        pkg_cfkun.first="Disk label:";
        pkg_cfkun.second=bskun->get_iso_label();
        //_msg_info("           Disk publisher:\t" + bskun->get_iso_publisher());
        pkg_cfkun1.first="Disk publisher:";
        pkg_cfkun1.second=bskun->get_iso_publisher();
        pkg_cfkun2.first="Disk application:";
        pkg_cfkun2.second=bskun->get_iso_application();
        //_msg_info("         Disk application:\t" + bskun->get_iso_application());
        show_conf_dkun(_msg_info,packun_v,pkg_cfkun,pkg_cfkun1,pkg_cfkun2);
        break;
    default:
        packun_v.first="";
        packun_v.second="";
        show_conf_dkun(_msg_info,packun_v,packun_v);
        break;
    }
}
int command_collection::command_iso(QString iso_name){
    if(bskun == nullptr) return 456;//nullptr
    img_name=iso_name;
    QString _iso_efi_boot_args="";
    QDir workd(bskun->get_work_dir());
    if(!workd.exists("iso/isolinux/isolinux.bin")){
        _msg_err("The file '" + bskun->get_work_dir ()+"/iso/isolinux/isolinux.bin' does not exist.");
        return 1;
    }
    if(!workd.exists("iso/isolinux/isohdpfx.bin")){
        _msg_err("The file '" + bskun->get_work_dir ()+"/iso/isolinux/isohdpfx.bin' does not exist.");
        return 1;
    }
    if(workd.exists("iso/EFI/archiso/efiboot.img")){
        _iso_efi_boot_args="-eltorito-alt-boot -e EFI/archiso/efiboot.img -no-emul-boot -isohybrid-gpt-basdat";
    }
    _show_config(ISO);
    QDir Outdir(bskun->get_out_dir());
    if(!Outdir.exists()){
        Outdir.cdUp();
        Outdir.mkdir(bskun->get_out_dir());
    }
    _msg_info("Creating ISO image...");
    QString xorriso_cmdkun="iso_label=\"" + bskun->get_iso_label()
            + "\"\niso_application=\"" + bskun->get_iso_application() + "\"\niso_publisher=\"" + bskun->get_iso_publisher()
            + "\"\nwork_dir=\"" + bskun->get_work_dir() + "\"\n_iso_efi_boot_args=\"" + _iso_efi_boot_args
            + "\"\nout_dir=\"" + bskun->get_out_dir() + "\"\nimg_name=\"" + img_name +
            "\"\nxorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid \"${iso_label}\" -appid \"${iso_application}\" -publisher \"${iso_publisher}\" -preparer \"prepared by mkalteriso\" "
            + "-eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -isohybrid-mbr ${work_dir}/iso/isolinux/isohdpfx.bin "
            + "${_iso_efi_boot_args} -output \"${out_dir}/${img_name}\" \"${work_dir}/iso/\"";
    _msg_infodbg(xorriso_cmdkun);
    int ret=system(xorriso_cmdkun.toUtf8().data());
    if(ret != 0){
        _msg_err(QString("xorriso! \n") + QString("Error code : ") + QString::number(ret));
        return 2;
    }
    _checksum_common(img_name);
    _msg_success("Done! " + bskun->get_out_dir() + "/" + img_name);
    return 0;
}
void command_collection::_checksum_common(QString sum_file){
    _msg_info("Creating md5 checksum ...");
    QString md5_cmdkun="out_dir=\"" + bskun->get_out_dir() + "\"\nimg_name=\"" + sum_file + "\"\ncd \"${out_dir}\"\nmd5sum \"${img_name}\" > \"${img_name}.md5\"";
    _msg_infodbg(md5_cmdkun);
    system(md5_cmdkun.toUtf8().data());
    _msg_info("Creating sha256 checksum ...");
    QString sha256_cmdkun="out_dir=\"" + bskun->get_out_dir() + "\"\nimg_name=\"" + sum_file + "\"\ncd \"${out_dir}\"\nsha256sum \"${img_name}\" > \"${img_name}.sha256\"";
    _msg_infodbg(sha256_cmdkun);
    system(sha256_cmdkun.toUtf8().data());

}
void command_collection::_msg_info(QString s){
    std::wcout << "[mkalteriso] INFO: " << s.toStdWString() << std::endl;
}
void command_collection::_msg_infodbg(QString s){
    if(!bskun->get_quiet() || bskun->get_debug_mode()){
        std::wcout << "\e[35m[mkalteriso] DEBUG: " << s.toStdWString() << "\e[0m" << std::endl;
    }
}
void command_collection::_msg_success(QString s){
    std::wcout << "\e[32m[mkalteriso] INFO: " << s.toStdWString() << "\e[0m" << std::endl;
}
void command_collection::_msg_err(QString s){
    std::wcerr << "\e[31m[mkalteriso] ERROR: " << s.toStdWString() << "\e[0m" << std::endl;
}

#include "command_collection.h"

command_collection::command_collection(QObject *parent) : QObject(parent)
{

}
void command_collection::set_build_setting(build_setting* bss){
    bskun=bss;
}
int command_collection::command_init(){
    _show_config(INIT);
    _chroot_init();
    return 0;
}
int command_collection::command_install(){
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
int command_collection::_chroot_init(){
    QDir dir(bskun->get_work_dir());
    if(!dir.exists("airootfs")){
        dir.mkpath("airootfs");
    }
    _pacman("base base-devel syslinux mkinitcpio");
    return 0;
}
int command_collection::command_run(){
    if(bskun->get_run_cmd() == ""){
        _msg_err("Not found command....\nYou must set command!");
        return 3;
    }
    _show_config(RUN);
    return _chroot_run();

}
int command_collection::_cleanup(){
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
    _msg_info(cmdkun_buf);
    system(cmdkun_buf.toUtf8().data());
    _msg_info("Done!");
    return 0;
}
int command_collection::_mkairootfs_sfs(){
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
    _msg_info(mksquashfs_cmd);
    system(mksquashfs_cmd.toUtf8().data());
    _msg_info("Done!");
    return 0;
}
int command_collection::command_prepare(){
    _show_config(PREPARE);
    _cleanup();
    if(bskun->get_sfs_mode() == "sfs"){
        _mkairootfs_sfs();
    }
    _mkchecksum();
    return 0;
}
void command_collection::_mksignature(){
    _msg_info("Creating signature file...");
    QString gpg_cmdkun="cd \"" + bskun->get_work_dir() + "/iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture()
            + "\"\ngpg --detach-sign --default-key " + bskun->get_gpg_key() + "airootfs.sfs";
    _msg_info(gpg_cmdkun);
    system(gpg_cmdkun.toUtf8().data());
    _msg_info("Done!");
}
void command_collection::_mkchecksum(){
    _msg_info("Creating checksum file for self-test...");
    QString sha512sum_cmdkun="cd \"" + bskun->get_work_dir() + "/iso/" + bskun->get_install_dir() + "/" + bskun->get_architecture()
            + "\"\nsha512sum airootfs.sfs > airootfs.sha512";
    _msg_info(sha512sum_cmdkun);
    system(sha512sum_cmdkun.toUtf8().data());
    if(bskun->get_use_gpg_key()){
        _mksignature();
    }
    _msg_info("Done!");
}
int command_collection::command_pkglist(){
    _msg_info("Creating a list of installed packages on live-enviroment...");
    QString pacman_cmdkun="work_dir=\"" + bskun->get_work_dir() + "\"\ninstall_dir=\"" + bskun->get_install_dir() + "\"\narch=\""
            +bskun->get_architecture() + "\"\npacman -Q --sysroot \"${work_dir}/airootfs\" > \"${work_dir}/iso/${install_dir}/pkglist.${arch}.txt\"";
    _msg_info(pacman_cmdkun);
    system(pacman_cmdkun.toUtf8().data());
    _msg_info("Done!");
    return 0;
}
int command_collection::_chroot_run(){
    QString workdir_safe=bskun->get_work_dir();
    workdir_safe=workdir_safe.replace(";","");
    QString command_strkun="arch-chroot " + workdir_safe + "/airootfs " + bskun->get_run_cmd() ;
    _msg_info(command_strkun);
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
    std::wcout << "Packages installed successfully!" << std::endl;
    return 0;
}
void command_collection::_show_config(show_config_type typekun){
    _msg_info("Configuration settings");
    _msg_info("               Command:\t" + bskun->get_command_args().at(0));
    _msg_info("          Architecture:\t" + bskun->get_architecture());
    _msg_info("     Working directory:\t" + bskun->get_work_dir());
    _msg_info("Installation directory:\t" + bskun->get_install_dir());
    switch(typekun){
    case INIT:
        _msg_info("    Pacman config file:\t" + bskun->get_pacman_conf());
        break;
    case INSTALL:
        _msg_info("    Pacman config file:\t" + bskun->get_pacman_conf());
        _msg_info("              Packages:\t" + bskun->get_pkg_list());
        break;
    case RUN:
        _msg_info("           Run command:\t" + bskun->get_run_cmd());

        break;
    case PREPARE:
        _msg_info("SquashFS compression type:\t" + bskun->get_sfs_comp());
        if(bskun->get_sfs_comp_opt() != ""){
            _msg_info("Squashfs compression opts:\t" + bskun->get_sfs_comp_opt());

        }
        break;
    case ISO:
        _msg_info("            Image name:\t" + img_name);
        _msg_info("            Disk label:\t" + bskun->get_iso_label());
        _msg_info("        Disk publisher:\t" + bskun->get_iso_publisher());
        _msg_info("      Disk application:\t" + bskun->get_iso_application());
        break;
    }
}
int command_collection::command_iso(QString iso_name){
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
    _msg_info(xorriso_cmdkun);
    system(xorriso_cmdkun.toUtf8().data());
    _mkisochecksum();
    _msg_info("Done! " + bskun->get_out_dir() + "/" + img_name);
    return 0;
}
void command_collection::_mkisochecksum(){
    _msg_info("Creating md5 checksum ...");
    QString md5_cmdkun="out_dir=\"" + bskun->get_out_dir() + "\"\nimg_name=\"" + img_name + "\"\ncd \"${out_dir}\"\nmd5sum \"${img_name}\" > \"${img_name}.md5\"";
    _msg_info(md5_cmdkun);
    system(md5_cmdkun.toUtf8().data());
    _msg_info("Creating sha256 checksum ...");
    QString sha256_cmdkun="out_dir=\"" + bskun->get_out_dir() + "\"\nimg_name=\"" + img_name + "\"\ncd \"${out_dir}\"\nsha256sum \"${img_name}\" > \"${img_name}.sha256\"";
    _msg_info(sha256_cmdkun);
    system(sha256_cmdkun.toUtf8().data());

}
void command_collection::_msg_info(QString s){
    std::wcout << "[mkalteriso] INFO: " << s.toStdWString() << std::endl;
}
void command_collection::_msg_err(QString s){
    std::wcerr << "\e[31m[mkalteriso] ERROR: " << s.toStdWString() << "\e[0m" << std::endl;
}

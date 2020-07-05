#ifndef COMMAND_COLLECTION_H
#define COMMAND_COLLECTION_H
#include <iostream>
#include <QObject>
#include <QFileInfo>
#include <QDir>
#include <stdio.h>
#include "build_setting.h"

class command_collection : public QObject
{
    Q_OBJECT
public:
    explicit command_collection(QObject *parent = nullptr);
    void set_build_setting(build_setting* bskun);
    int command_init();
    int command_install();
    int command_install_file();
    int command_run();
    int command_prepare();
    int command_pkglist();
    int command_tarball(QString);
    int command_iso(QString);
    void force_umount();
private:
    build_setting* bskun=nullptr;
    bool umount_kun;
    enum show_config_type{
        INIT=0,
        INSTALL=1,
        RUN=2,
        PREPARE=3,
        ISO=4
    };
    void _show_config(show_config_type typekun);
    static void _msg_info(QString s);
    static void _msg_err(QString s);
    static void _msg_success(QString s);
    int _chroot_init();
    int _chroot_run();
    int _pacman(QString );
    int _pacman_file(QString );
    int _cleanup();
    int _mkairootfs_sfs();
    void _mkchecksum();
    void _mksignature();
    void _checksum_common(QString) ;
    void _msg_infodbg(QString);
    int _mkairootfs_img();
    int _mount_airootfs();
    template<class... LNKUN> int max_lenkun(LNKUN... args);
    template<class... LNKUNS> int max_lenkun_QString(LNKUNS... args);
    template<class... SHOWVALKUN> void show_conf_l(int maxkun,void (*do_msgshow)(QString),SHOWVALKUN... txtargkun);
    template<class... SHOWVALKUN> void show_conf_l(void (*do_msgshow)(QString),SHOWVALKUN... txtargkun);
    void _umount_airootfs();
    template<class... SHOWVALKUN> void show_conf_dkun(void (*do_msgshow)(QString),SHOWVALKUN... argkun);
    QString img_name;
    static void stubkun(QString);
    struct show_valkun{
        QString first;
        QString second;
    };
signals:

};

#endif // COMMAND_COLLECTION_H

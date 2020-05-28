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
    int command_run();
    int command_prepare();
    int command_pkglist();
    int command_iso(QString);
private:
    build_setting* bskun;

    enum show_config_type{
        INIT=0,
        INSTALL=1,
        RUN=2,
        PREPARE=3,
        ISO=4
    };
    void _show_config(show_config_type typekun);
    void _msg_info(QString s);
    void _msg_err(QString s);
    void _msg_success(QString s);
    int _chroot_init();
    int _chroot_run();
    int _pacman(QString );
    int _cleanup();
    int _mkairootfs_sfs();
    void _mkchecksum();
    void _mksignature();
    void _mkisochecksum() ;
    QString img_name;
signals:

};

#endif // COMMAND_COLLECTION_H

#ifndef BUILD_SETTING_H
#define BUILD_SETTING_H

#include <QObject>
#include <QString>
class build_setting : public QObject
{
    Q_OBJECT
public:
    explicit build_setting(QObject *parent = nullptr);
    QString get_architecture();
    void set_architecture(QString);
    QString get_pacman_conf();
    void set_pacman_conf(QString);
    QString get_install_dir();
    void set_install_dir(QString);
    QString get_work_dir();
    void set_work_dir(QString);
    QString get_out_dir();
    void set_out_dir(QString);
    QString get_sfs_mode();
    void set_sfs_mode(QString);
    QString get_sfs_comp();
    void set_sfs_comp(QString);
    QString get_sfs_comp_opt();
    void set_sfs_comp_opt(QString);
    QString get_pkg_list();
    void set_pkg_list(QString);
    QString get_run_cmd();
    void set_run_cmd(QString);
    QString get_iso_label();
    void set_iso_label(QString);
    QString get_iso_publisher();
    void set_iso_publisher(QString);

    QString get_iso_application();
    void set_iso_application(QString);
    bool get_quiet();
    void set_quiet(bool);
    QString get_gpg_key();
    void set_gpg_key(QString);
    bool get_use_gpg_key();
    void set_use_gpg_key(bool);
    QStringList get_command_args();
    void set_command_args(QStringList);
private:
    bool quiet;
    QString architecture;
    QString pacman_conf;
    QString install_dir;
    QString work_dir;
    QString out_dir;
    QString sfs_mode;

    QString sfs_comp;
    QString sfs_comp_opt;
    QString pkg_list;
    QString run_cmd;
    QString iso_label;
    QString iso_publisher;
    QString iso_application;
    QString gpg_key;
    bool use_gpg_key;
    QStringList command_args;
signals:

};

#endif // BUILD_SETTING_H

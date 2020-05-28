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
private:

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
signals:

};

#endif // BUILD_SETTING_H

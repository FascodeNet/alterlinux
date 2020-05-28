#include "main.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    AppMain m(0,&a);
    QTimer::singleShot(0,&m,SLOT(run()));
    return a.exec();
}
bool isroot(){
    uid_t uid  = {0};
    uid=getuid();
    if(uid == 0){
        return true;
    }else{
    return false;
    }
}
AppMain::AppMain(QObject *parent, QCoreApplication* coreApp)
    : QObject(parent)
    , app(coreApp)
  {
  }
void AppMain::run()
{
    if(!isroot()){
        std::wcerr << "This command must be run as root." << std::endl;
        app->exit(810);
        return;
    }
    if(uname(&uname_strkun)!=0){
        std::wcerr << "Uname failed!" << std::endl;
        app->exit(809);
        return;
    }
    umask(0077); //permission
    // commandline_parse
    build_setting_obj.set_architecture(uname_strkun.machine);
    build_setting_obj.set_pacman_conf("/etc/pacman.conf");
    build_setting_obj.set_install_dir("alter");
    build_setting_obj.set_work_dir("work");
    build_setting_obj.set_out_dir("out");
    build_setting_obj.set_sfs_mode("sfs");
    build_setting_obj.set_sfs_comp("zstd");
    build_setting_obj.set_sfs_comp_opt("");
    build_setting_obj.set_pkg_list("");
    build_setting_obj.set_run_cmd("");
    build_setting_obj.set_iso_application("Alter Linux Live/Rescue CD");
    build_setting_obj.set_quiet(false);
    build_setting_obj.set_use_gpg_key(false);
    time_t     now;
    struct tm  *ts;
    char       buf[80];
    now = time(NULL);
    ts=localtime(&now);
    strftime(buf, sizeof(buf), "ALTER_%Y%m",ts);
    build_setting_obj.set_iso_label(QString(buf));
    build_setting_obj.set_iso_publisher("Fascode Network <https://fascode.net>");
    QCommandLineParser parser;
    parser.setApplicationDescription("mkalteriso");
    QCommandLineOption option_Architecture("a","Set Architecture","Architecture",build_setting_obj.get_architecture());
    QCommandLineOption option_PACKAGE("p","Package(s) to install, can be used multiple times","PACKAGE(S)","");
    QCommandLineOption option_command("r","Run <command> inside airootfs","command",build_setting_obj.get_run_cmd());
    QCommandLineOption option_file_pacman("C","Config file for pacman.\nDefault: '" + build_setting_obj.get_pacman_conf() +"'\nDefault: \'" + build_setting_obj.get_install_dir() + "'\nNOTE: Max 8 characters, use only [a-z0-9]","file",build_setting_obj.get_pacman_conf());
    QCommandLineOption option_work_dir("w","Set the working directory\nDefault: \'" + build_setting_obj.get_work_dir() + "'","work_dir",build_setting_obj.get_work_dir());
    QCommandLineOption option_out_dir("o","Set the output directory\nDefault: '" + build_setting_obj.get_out_dir() + "'","out_dir",build_setting_obj.get_out_dir());
    QCommandLineOption option_sfs_mode("s","Set SquashFS image mode (img or sfs)\nimg: prepare airootfs.sfs for dm-snapshot usage\nsfs: prepare airootfs.sfs for overlayfs usage\nDefault: "
                                       + build_setting_obj.get_sfs_mode(),"sfs_mode",build_setting_obj.get_sfs_mode());
    QCommandLineOption option_sfs_comp("c","Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)\nDefault: '" + build_setting_obj.get_sfs_comp() + "'","comp_type",build_setting_obj.get_sfs_comp());
    QCommandLineOption option_sfs_special_option("t","Set compressor-specific options. Run 'mksquashfs -h' for more help.\nDefault: empty","options",build_setting_obj.get_sfs_comp_opt());
    QCommandLineOption option_commands("commands","Show Commands");
    QCommandLineOption option_iso_label("L","iso file label\nDefault : " + build_setting_obj.get_iso_label(),"label",build_setting_obj.get_iso_label());
    QCommandLineOption option_iso_publisher("P","publisher\nDefault : " + build_setting_obj.get_iso_publisher(),"iso publisher",build_setting_obj.get_iso_publisher());
    QCommandLineOption option_iso_application("A","iso application\nDefault : " + build_setting_obj.get_iso_application(),"iso application",build_setting_obj.get_iso_application());
    QCommandLineOption option_install_dir("D","install dir\nDefault : " + build_setting_obj.get_install_dir(),"install dir",build_setting_obj.get_install_dir());
    QCommandLineOption option_verbose("verbose","verbose");
    QCommandLineOption option_gpg_key("g","gpg key","gpg key");
    parser.addOptions({option_Architecture,option_PACKAGE,option_command,option_file_pacman,option_work_dir
                      ,option_out_dir,option_sfs_mode,option_sfs_comp,option_sfs_special_option,option_iso_label,option_iso_publisher,option_iso_application,option_install_dir
                      ,option_gpg_key});
    parser.addOption(option_verbose);
    parser.addOption(option_commands);

    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineParser commandkun_parser;
    commandkun_parser.setApplicationDescription("command");
    parser.addPositionalArgument("command","command");
    parser.addPositionalArgument("<command options>","command option");
    if(app->arguments().count() == 1){
        parser.showHelp();
        app->exit(1);
        return;
    }
    parser.process(app->arguments());
    if(parser.positionalArguments().count() == 0){
        std::wcout << "Commands:\n\tinit\n\t\tMake base layout and install base group\n\tinstall\n\t\tInstall all specified packages (-p)\n\trun\n\t\trun command specified by -r\n\tprepare\n\t\tbuild all images\n\tpkglist\n\t\tmake a pkglist.txt of packages installed on airootfs\n\tiso <image name>\n\t\tbuild an iso image from the working dir" << std::endl;
        app->exit(1);
        return;
    }
    commandkun_parser.parse(parser.positionalArguments());
    if(parser.isSet(option_commands)){
        std::wcout << "Commands:\n\tinit\n\t\tMake base layout and install base group\n\tinstall\n\t\tInstall all specified packages (-p)\n\trun\n\t\trun command specified by -r\n\tprepare\n\t\tbuild all images\n\tpkglist\n\t\tmake a pkglist.txt of packages installed on airootfs\n\tiso <image name>\n\t\tbuild an iso image from the working dir" << std::endl;
    }
    build_setting_obj.set_pacman_conf(parser.value(option_file_pacman));
    build_setting_obj.set_architecture(parser.value(option_Architecture));
    build_setting_obj.set_pkg_list(build_setting_obj.get_pkg_list() + parser.value(option_PACKAGE));
    build_setting_obj.set_run_cmd(parser.value(option_command));
    build_setting_obj.set_iso_label(parser.value(option_iso_label));
    build_setting_obj.set_iso_publisher(parser.value(option_iso_publisher));
    build_setting_obj.set_iso_application(parser.value(option_iso_application));
    build_setting_obj.set_out_dir(parser.value(option_out_dir));
    build_setting_obj.set_work_dir(parser.value(option_work_dir));
    build_setting_obj.set_install_dir(parser.value(option_install_dir));
    build_setting_obj.set_sfs_comp(parser.value(option_sfs_comp));
    build_setting_obj.set_sfs_mode(parser.value(option_sfs_mode));
    build_setting_obj.set_sfs_comp_opt(parser.value(option_sfs_special_option));
    if(parser.isSet(option_verbose)){
        build_setting_obj.set_quiet(false);
    }
    if(parser.isSet(option_gpg_key)){
        build_setting_obj.set_use_gpg_key(true);
        build_setting_obj.set_gpg_key(parser.value(option_gpg_key));
    }
    build_setting_obj.set_command_args(parser.positionalArguments());
    cmd_collect.set_build_setting(&build_setting_obj);
    if(parser.positionalArguments().at(0)=="init"){
        app->exit(cmd_collect.command_init());
        return;
    }
    if(parser.positionalArguments().at(0) == "install"){
        app->exit(cmd_collect.command_install());
        return;
    }
    app->exit();
}

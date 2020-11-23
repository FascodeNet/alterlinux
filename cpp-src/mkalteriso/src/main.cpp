#include "main.hpp"

int popen2(int *fd_r, int *fd_w,Vector<String> args) {

    // 子から親への通信用パイプ
    int pipe_child2parent[2];

    // 親から子への通信用パイプ
    int pipe_parent2child[2];

    // プロセスID
    int pid;

    // パイプを生成
    if (pipe(pipe_child2parent) < 0) {
        // パイプ生成失敗
        perror("popen2");
        return 1;
    }

    // パイプを生成
    if (pipe(pipe_parent2child) < 0) {
        // パイプ生成失敗
        perror("popen2");

        // 上で開いたパイプを閉じてから終了
        close(pipe_child2parent[READ]);
        close(pipe_child2parent[WRITE]);
        return 1;
    }

    // fork
    if ((pid = fork()) < 0) {
        // fork失敗
        perror("popen2");

        // 開いたパイプを閉じる
        close(pipe_child2parent[READ]);
        close(pipe_child2parent[WRITE]);

        close(pipe_parent2child[READ]);
        close(pipe_parent2child[WRITE]);

        return 1;
    }

    // 子プロセスか？
    if (pid == 0) {
        // 子プロセスの場合は、親→子への書き込みはありえないのでcloseする
        close(pipe_parent2child[WRITE]);

        // 子プロセスの場合は、子→親の読み込みはありえないのでcloseする
        close(pipe_child2parent[READ]);

        // 親→子への出力を標準入力として割り当て
        dup2(pipe_parent2child[READ], 0);

        // 子→親への入力を標準出力に割り当て
        dup2(pipe_child2parent[WRITE], 1);

        // 割り当てたファイルディスクリプタは閉じる
        close(pipe_parent2child[READ]);
        close(pipe_child2parent[WRITE]);

        // 子プロセスはここで該当プログラムを起動しリターンしない

        char** argskun=NULL;
        argskun=new char*[args.size() + 2];
        for(size_t i=0;i<args.size();i++){
                argskun[i]=(char*)args[i].c_str();
        }
        argskun[args.size()]=NULL;
        if (execvp(argskun[0],argskun) < 0) {
            perror("popen2");
            close(pipe_parent2child[READ]);
            close(pipe_child2parent[WRITE]);
            return 1;
        }
    }

    // 親プロセス側の処理
    close(pipe_parent2child[READ]);
    close(pipe_child2parent[WRITE]);

    *fd_r = pipe_child2parent[READ];
    *fd_w = pipe_parent2child[WRITE];

    return pid;
}

int main(int argc,char* argv[]){
    cmdline::parser p;
    p.add<String>("application",'A',"Set an application name for the ISO",false,app_name);
    p.add<String>("pacman_config",'C',"pacman configuration file.",false,pacman_conf);
    p.add("help", 'h', "This message");
    p.add<String>("install_dir",'D',"Set an install_dir. All files will by located here.\n\t\t\t NOTE: Max 8 characters, use only [a-z0-9]",
    false,install_dir);
    p.add<String>("iso_label",'L',"Set the ISO volume label",false,iso_label);
    p.add<String>("iso_pub",'P',"Set the ISO publisher",false,iso_publisher);
    p.add<String>("gpg-key",'g',"Set the GPG key to be used for signing the sqashfs image",false,"");
    p.add<String>("out_dir",'O',"Set the output directory",false,out_dir);
    p.add<String>("packages",'p',"Package(s) to install, can be used multiple times",false,aditional_packages);
    p.add("verbose",'v',"Enable verbose output");
    p.add<String>("work",'w',"Set the working directory",false,work_dir);
    p.add<String>("run_cmd",'r',"run command");
    if (!p.parse(argc, argv)||p.exist("help")){
        std::cout<<p.error_full()<<p.usage();
        return 0;
    }
    app_name=p.get<String>("application");
    pacman_conf=p.get<String>("pacman_config");
    install_dir=p.get<String>("install_dir");
    iso_label=p.get<String>("iso_label");
    iso_publisher=p.get<String>("iso_pub");
    gpg_key=p.get<String>("gpg-key");
    out_dir=p.get<String>("out_dir");
    aditional_packages=p.get<String>("packages");
    work_dir=p.get<String>("work");
    run_cmd=p.get<String>("run_cmd");
    Vector<String> cmd_ls=p.rest();
    if(cmd_ls.size()==0){
        _msg_error("No profile specified");
        return 0;
    }
    profile=realpath(cmd_ls.at(0));
    airootfs_dir=work_dir + "/airootfs";
    isofs_dir=work_dir+"/iso";
    return 0;
}
void _msg_error(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::ERR,app_name,msg_con);
}
void _msg_info(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::INFO,app_name,msg_con);
}
void _msg_warn(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::WARN,app_name,msg_con);
}
void _msg_debug(String msg_con){
    FascodeUtil::msg mskun;
    mskun.print(FascodeUtil::DEBUG,app_name,msg_con);
}

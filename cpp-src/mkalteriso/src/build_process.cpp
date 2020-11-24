#include "build_process.hpp"
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
void _build_profile(){
    bp2.airootfs_dir=bp2.work_dir + "/" + bp2.arch + "/airootfs";
    bp2.isofs_dir=bp2.work_dir + "/iso";
    bp2.iso_name=bp2.iso_name + "-" + bp2.iso_version + "-" + bp2.arch + ".iso";
    if(!dir_exist(bp2.work_dir)){
        str_mkdir(bp2.work_dir,S_IREAD | S_IWRITE);
    }
    {
        std::ofstream build_date_stream(bp2.work_dir + "/build_date");
        build_date_stream << bp2.SOURCE_DATE_EPOCH;
        build_date_stream.close();

    }
    
    
}
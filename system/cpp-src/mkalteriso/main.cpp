#include "main.h"
int main(int argc, char *argv[])
{
    if(!isroot()){
        std::cerr << "This command must be run as root." << std::endl;
        return 810;
    }
    return 0;
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

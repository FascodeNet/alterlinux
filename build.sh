#!/usr/bin/env bash

script_path="$(cd "$(dirname "$0")" || exit 1; pwd)"
channel_dir=""
out_dir="${script_path}/out"



#shellcheck source=./default.conf
#source "${script_path}/default.conf"

# shellcheck source=./lib/parsearg.sh
source "${script_path}/lib/parsearg.sh"


check_channel(){
    :
}

make_pkglist(){
    :
}

#make_profiledef





#ARGUMENT=("${DEFAULT_ARGUMENT[@]}" "${@}")
#getopt -Q \
#    -o "a:bc:deg:hjk:l:o:p:rt:u:w:x" \
#    -l "arch:,boot-splash,comp-type:,debug,cleaning,cleanup,gpgkey:,help,lang:,japanese,kernel:,out:,password:,comp-opts:,user:,work:,bash-debug,nocolor,noconfirm,nodepend,gitversion,msgdebug,noloopmod,tarball,noiso,noaur,nochkver,channellist,config:,noefi,nodebug,nosigcheck,normwork,log,logpath:,nolog,nopkgbuild,pacman-debug,confirm,tar-type:,tar-opts:,add-module:,nogitversion,cowspace:,rerun,depend,loopmod" \
#    -- "${ARGUMENT[@]}"|| exit 1

#readarray -t OPT < <(getopt "${GETOPT[@]}") # 配列に代入
#eval set -- "${OPT[*]}"
#msg_debug "Argument: ${OPT[*]}"
#unset OPT DEFAULT_ARGUMENT


#channel_dir="${1-""}"

parsearg "$@"
echo "$boot_splash"
echo "$cleaning"


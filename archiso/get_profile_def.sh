#!/usr/bin/env bash
PROFILE_FILE=""
SOURCE_FILE=""
OUT_FILE=""
usage_exit() {
        echo "Usage: $0 -p [PROFILEDEF PATH] -s [SOURCE FILE NAME] -o [OUT FILE]" 1>&2
        exit 1
}

while getopts p:s:o:h OPT
do
    case $OPT in
        p)  PROFILE_FILE=$OPTARG
            ;;
        s)  SOURCE_FILE=$OPTARG
            ;;
        o)  OUT_FILE=$OPTARG
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))
if [[ ! -f ${PROFILE_FILE} ]]; then
    exit 810
fi
source ${PROFILE_FILE}
bootmodes_js="stub"
for pf in ${bootmodes[@]}
do
    bootmodes_js="${bootmodes_js},\"${pf}\""
done
bootmodes_js=$(echo ${bootmodes_js} | sed "s/stub,//g")
cat ${SOURCE_FILE} | sed "s|ISONAME|${iso_name}|g" | sed "s|ISOLABEL|${iso_label}|g" | sed "s|ISOPUB|${iso_publisher}|g" | \
sed "s|ISOAPP|${iso_application}|g" | sed "s|ISOVER|${iso_version}|g" | sed "s|INSTALLDIR|${install_dir}|g" | sed "s|ARCH|${arch}|g" \
| sed "s|PACMANCONF|${pacman_conf}|g" | sed "s|\"BOOTMODES\"|${bootmodes_js}|g" > ${OUT_FILE}
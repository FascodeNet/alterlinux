#!/usr/bin/env bash
PROFILE_FILE=""
SECTION_NAME=""
usage_exit() {
        echo "Usage: $0 -p [PROFILEDEF PATH] -s [SECTION NAME]" 1>&2
        exit 1
}

while getopts p:s:h OPT
do
    case $OPT in
        p)  PROFILE_FILE=$OPTARG
            ;;
        s)  SECTION_NAME=$OPTARG
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))

source "${PROFILE_FILE}"
eval echo "\${${SECTION_NAME}}"
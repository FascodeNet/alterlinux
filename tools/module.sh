#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# build.sh
#
# The main script that runs the build
#

set -e
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Scripts that perform operations related to modules" 
    echo
    echo " General command:"
    echo "    check [name]              Determine if the locale is available"
    echo "    show                      Shows a list of available locales"
    echo "    depend [name]             Shows the modules that the module depends on"
    echo "    help                      This help message"
    echo
    echo " General options:"
    echo "    -h | --help               This help message"
}




# Parse options
ARGUMENT="${@}"
OPTS="h"
OPTL="help"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- ${ARGUMENT}); then
    exit 1
fi

eval set -- "${OPT}"
unset OPT OPTL OPTS

while true; do
    case "${1}" in
        -h | --help)
            _help
            exit 0
            ;;
        --)
            shift 1
            break
            ;;

    esac
done

if [[ -z "${1}" ]]; then
    _help
    exit 1
else
    COMMAND="${1}"
    shift 1
fi

case "${COMMAND}" in
    "help"  ) _help; exit 0 ;;
    *       ) _help; exit 1 ;;
esac

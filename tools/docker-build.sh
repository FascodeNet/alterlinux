#!/usr/bin/env bash
set -e

if [[ $UID != 0 ]]; then
    echo "You have to run this as root." 1>&2
    exit 1
fi

if ! type docker >/dev/null 2>&1; then
    echo "You have to install docker." 1>&2
    exit 1
fi

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

_usage () {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -o | --build-opiton \"[options]\"     Send the build option to build.sh"
    echo "    -c | --clean                          Enable --no-cache option when build docker image"
    echo "    -s | --no-share-pkgfile               Disable pacman pkgcache"
    echo "    -p | --pkg-cache-dir \"[path]\"       Select pacman pkg cache directory"
    echo "    -h | --help                           This help message and exit"
    echo
}

# Start define var
[[ -d /var/cache/pacman/pkg ]] && [[ -d /var/lib/pacman/sync ]] && SHARE_PKG_DIR='/var/cache/pacman/pkg' && SHARE_DB_DIR='/var/lib/pacman/sync' || SHARE_PKG_DIR=${script_path}/cache/pkg && SHARE_DB_DIR=${script_path}/cache/sync
# End define var


# Start parse options
ARGUMENT="${@}"
while (( $# > 0 )); do
    case ${1} in
        -o | --build-opiton)
            BUILD_OPT="${2}"
            shift 2
            ;;
        -c | --clean)
            NO_CACHE="--no-cache" # Enable --no-cache option
            shift 1
            ;;
        -s | --no-share-pkgfile)
            NO_SHARE_PKG=True
            shift 1
            ;;
        -p | --pkg-cache-dir)
            [[ -d ${2} ]] && mkdir -p ${2}/pkg && mkdir -p ${2}/sync && SHARE_PKG_DIR=${2}/pkg && SHARE_DB_DIR=${2}/sync || echo "Error: The directory is not found or cannot make directory." 1>&2 && exit 1
            ;;
        -h | --help)
            _usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            msg_error "Invalid argument '${1}'"
            _usage 1
            ;;
    esac
done
# End parse options

cd $script_path
docker build ${NO_CACHE} -t alterlinux-build:latest .
[[ "${NO_SHARE_PKG}" == "True" ]] && SHARE_PACMAN_DIR="" || SHARE_PACMAN_DIR="-v ${SHARE_PKG_DIR}:/var/cache/pacman/pkg -v ${SHARE_DB_DIR}:/var/lib/pacman/sync"
docker run -e _DOCKER=true -t -i --privileged -v $script_path/out:/alterlinux/out -v /usr/lib/modules:/usr/lib/modules:ro ${SHARE_PACMAN_DIR} alterlinux-build "${BUILD_OPT}"

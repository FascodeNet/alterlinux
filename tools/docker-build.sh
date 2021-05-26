#!/usr/bin/env bash
set -e

if ! type docker >/dev/null 2>&1; then
    echo "You have to install docker in your system before." 1>&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    cat - 1>&2 <<EOF
Cannot connect to docker socket.
Please make sure that you have the right permission to use docker and the docker daemon has been running correctly.
EOF
    exit 1
fi

script_path=$(cd -P $(dirname $(readlink -f ${0})) && cd .. && pwd)

_usage () {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -o | --build-opiton \"[options]\"     Set build options passed to build.sh"
    echo "    -d | --dist-out-dir \"[path]\"        Set distributions' output directory"
    echo "    -n | --noninteractive                 The process will not ask you any questions"
    echo "    -c | --clean                          Enable --no-cache option when building docker image"
    echo "    -s | --no-share-pkgfile               Disable pacman pkgcache"
    echo "    -p | --pkg-cache-dir \"[path]\"       Set pacman pkg cache directory"
    echo "    -h | --help                           This help message and exit"
    echo
}

# Start define var
if [[ -d /var/cache/pacman/pkg ]] && [[ -d /var/lib/pacman/sync ]]; then
    SHARE_PKG_DIR=/var/cache/pacman/pkg
    SHARE_DB_DIR=/var/lib/pacman/sync
else
    SHARE_PKG_DIR=${script_path}/cache/pkg
    SHARE_DB_DIR=${script_path}/cache/sync
fi
# End define var

# Start parse options
DIST_DIR=${script_path}/out
DOCKER_BUILD_OPTS=()
BUILD_SCRIPT_OPTS=()
while (( $# > 0 )); do
    case ${1} in
        -o | --build-opiton)
            # -o: dists output dir option in build.sh
            if [[ ${2} == *"-o"* ]]; then
                echo "The -o option cannot be set with docker build. Please use -d option instead." 1>&2
                exit 1
            fi
            #
            BUILD_SCRIPT_OPTS+=(${2})
            shift 2
            ;;
        -d | --dist-out-dir)
            mkdir -p ${2} || {
                echo "Error: failed creating output directory: ${2}" 1>&2
                exit 1
            }
            DIST_DIR=$(cd -P ${2} && pwd)
            shift 2
            ;;
        -n | --noninteractive)
            BUILD_SCRIPT_OPTS+=(--noconfirm)
            shift 1
            ;;
        -c | --clean)
            # Enable docker's --no-cache option
            DOCKER_BUILD_OPTS+=(--no-cache)
            shift 1
            ;;
        -s | --no-share-pkgfile)
            NO_SHARE_PKG=True
            shift 1
            ;;
        -p | --pkg-cache-dir)
            if [[ -d ${2} ]] && \
                mkdir -p ${2}/pkg && \
                mkdir -p ${2}/sync
            then
                SHARE_PKG_DIR=${2}/pkg
                SHARE_DB_DIR=${2}/sync
            else
                echo "Error: The directory is not found or cannot make directory." 1>&2
                exit 1
            fi
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

DOCKER_RUN_OPTS=()
DOCKER_RUN_OPTS+=(-v ${DIST_DIR}:/alterlinux/out)
DOCKER_RUN_OPTS+=(-v /usr/lib/modules:/usr/lib/modules:ro)
[[ "x${NO_SHARE_PKG}" != "xTrue" ]] && {
    DOCKER_RUN_OPTS+=(-v ${SHARE_PKG_DIR}:/var/cache/pacman/pkg)
    DOCKER_RUN_OPTS+=(-v ${SHARE_DB_DIR}:/var/lib/pacman/sync)
}

[[ "x$(tty)" != "x" ]] && OPT_TTY="-t" || OPT_TTY=""

echo docker build ${DOCKER_BUILD_OPTS[@]} -t alterlinux-build:latest ${script_path}
echo docker run --rm -i ${OPT_TTY} --privileged -e _DOCKER=true ${DOCKER_RUN_OPTS[@]} alterlinux-build ${BUILD_SCRIPT_OPTS[@]}

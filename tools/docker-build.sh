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
cd $SCRIPT_DIR
docker build -t alterlinux-build:latest .
docker run -e _DOCKER=true -t -i --privileged -v $SCRIPT_DIR/out:/alterlinux/out -v /usr/lib/modules:/usr/lib/modules:ro alterlinux-build

#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

cd "${script_path}"
sudo make clean
sudo rm -f "${script_path}/system/mkalteriso"

cd - > /dev/null

#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && pwd )"

cd "${script_path}"
sudo make clean
cd - > /dev/null

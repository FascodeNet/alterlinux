#!/usr/bin/env bash

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"$script_path/clean.sh"
exec go run "$script_path/src" profile generate \
    --bootloaders "$script_path/bootloaders/"\
    --modules "$script_path/modules/" \
    -o "$script_path/out" "$@"

#!/usr/bin/env bash

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -rf "$script_path/out"
"$script_path/gen.sh" "$script_path/configs/xfce" || exit $?

sudo ../archiso/mkarchiso -v -w "$script_path/work" -o "$script_path/out" "$script_path/out/xfce"

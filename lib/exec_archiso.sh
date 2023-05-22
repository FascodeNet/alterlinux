#!/usr/bin/env bash
# shellcheck disable=SC2154

exec_archiso(){
    git clone "https://github.com/FascodeNet/archiso-alter" "$work_dir/archiso-alter"
    bash "$work_dir/archiso-alter/archiso/mkarchiso" -v -w "$work_dir/build" -o "$out_dir" "$@" "$work_dir/profile"

}

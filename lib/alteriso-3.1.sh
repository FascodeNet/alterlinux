#-- AlterISO 3.1 functions --#
# これらの関数は現在実行されません。それぞれの関数はAlterISO 4.0への移植後に削除してください。

# Add files to the root of isofs
make_overisofs() {
    local _over_isofs_list _isofs
    _over_isofs_list=("${channel_dir}/over_isofs.any""${channel_dir}/over_isofs.${arch}")
    for_module '_over_isofs_list+=("${module_dir}/{}/over_isofs.any" "${module_dir}/{}/over_isofs.${arch}")'
    for _isofs in "${_over_isofs_list[@]}"; do
        [[ -d "${_isofs}" ]] && [[ -n "$(find "${_isofs}" -mindepth 1 -maxdepth 2)" ]] &&  cp -af "${_isofs}"/* "${isofs_dir}"
    done

    return 0
}


#-- AlterISO 3.1 functions --#
# これらの関数は現在実行されません。それぞれの関数はAlterISO 4.0への移植後に削除してください。

# Build airootfs filesystem image
make_prepare() {
    mount_airootfs

    # Create packages list
    _msg_info "Creating a list of installed packages on live-enviroment..."
    pacman-key --init
    pacman -Q --sysroot "${pacstrap_dir}" | tee "${isofs_dir}/${install_dir}/pkglist.${arch}.txt" "${build_dir}/packages-full.list" > /dev/null

    # Cleanup
    remove "${pacstrap_dir}/root/optimize_for_tarball.sh"
    _cleanup_pacstrap_dir

    # Create squashfs
    mkdir -p -- "${isofs_dir}/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    mksquashfs "${pacstrap_dir}" "${build_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp "${sfs_comp}" "${sfs_comp_opt[@]}"

    # Create checksum
    _msg_info "Creating checksum file for self-test..."
    echo "$(sha512sum "${isofs_dir}/${install_dir}/${arch}/airootfs.sfs" | getclm 1) airootfs.sfs" > "${isofs_dir}/${install_dir}/${arch}/airootfs.sha512"
    _msg_info "Done!"

    # Sign with gpg
    if [[ -v gpg_key ]] && (( "${#gpg_key}" != 0 )); then
        _msg_info "Creating signature file ($gpg_key) ..."
        cd -- "${isofs_dir}/${install_dir}/${arch}"
        gpg --detach-sign --default-key "${gpg_key}" "airootfs.sfs"
        cd -- "${OLDPWD}"
        _msg_info "Done!"
    fi

    umount_work

    [[ "${cleaning}" = true ]] && remove "${pacstrap_dir}" "${pacstrap_dir}.img"

    return 0
}

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


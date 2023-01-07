#!/usr/bin/env bash

# Set up custom pacman.conf with custom cache and pacman hook directories.
_make_pacman_conf() {
    local _cache_dirs _system_cache_dirs _profile_cache_dirs _pacman_conf
    local _pacman_conf_list=("${script_path}/pacman-${arch}.conf" "${channel_dir}/pacman-${arch}.conf" "${script_path}/system/pacman-${arch}.conf")

    # Pacman configuration file used only when building
    # If there is pacman.conf for each channel, use that for building
    for _pacman_conf in "${_pacman_conf_list[@]}"; do
        if [[ -f "${_pacman_conf}" ]]; then
            pacman_conf="${_pacman_conf}"
            break
        fi
    done
    _msg_debug "Use ${pacman_conf}"

    _msg_info "Copying custom pacman.conf to work directory..."
    _msg_info "Using pacman CacheDir: ${cache_dir}"
    # take the profile pacman.conf and strip all settings that would break in chroot when using pacman -r
    # append CacheDir and HookDir to [options] section
    # HookDir is *always* set to the airootfs' override directory
    # see `man 8 pacman` for further info
    pacman-conf --config "${pacman_conf}" | \
        sed "/CacheDir/d;/DBPath/d;/HookDir/d;/LogFile/d;/RootDir/d;/\[options\]/a CacheDir = ${cache_dir}
        /\[options\]/a HookDir = ${pacstrap_dir}/etc/pacman.d/hooks/
        /\[options\]/a DBPath  = ${pacstrap_dir}/var/lib/pacman/" > "${build_dir}/${buildmode}.pacman.conf"

    [[ "${nosigcheck}" = true ]] && sed -i "/SigLevel/d; /\[options\]/a SigLebel = Never" "${pacman_conf}"

    [[ -n "$(find "${cache_dir}" -maxdepth 1 -name '*.pkg.tar.*' 2> /dev/null)" ]] && _msg_info "Use cached package files in ${cache_dir}"

    _msg_info "Done!"
}



# Customize installation.
_make_customize_airootfs() {
    local passwd=()

    #if [[ -e "${profile}/airootfs/etc/passwd" ]]; then
    #    _msg_info "Copying /etc/skel/* to user homes..."
    #    while IFS=':' read -a passwd -r; do
    #       # Only operate on UIDs in range 1000–59999
    #        (( passwd[2] >= 1000 && passwd[2] < 60000 )) || continue
    #        # Skip invalid home directories
    #        [[ "${passwd[5]}" == '/' ]] && continue
    #        [[ -z "${passwd[5]}" ]] && continue
    #        # Prevent path traversal outside of $pacstrap_dir
    #        if [[ "$(realpath -q -- "${pacstrap_dir}${passwd[5]}")" == "${pacstrap_dir}"* ]]; then
    #            if [[ ! -d "${pacstrap_dir}${passwd[5]}" ]]; then
    #                install -d -m 0750 -o "${passwd[2]}" -g "${passwd[3]}" -- "${pacstrap_dir}${passwd[5]}"
    #            fi
    #            cp -dnRT --preserve=mode,timestamps,links -- "${pacstrap_dir}/etc/skel/." "${pacstrap_dir}${passwd[5]}"
    #            chmod -f 0750 -- "${pacstrap_dir}${passwd[5]}"
    #            chown -hR -- "${passwd[2]}:${passwd[3]}" "${pacstrap_dir}${passwd[5]}"
    #        else
    #            _msg_error "Failed to set permissions on '${pacstrap_dir}${passwd[5]}'. Outside of valid path." 1
    #        fi
    #    done < "${profile}/airootfs/etc/passwd"
    #    _msg_info "Done!"
    #fi


    # customize_airootfs options
    # -b                        : Enable boot splash.
    # -d                        : Enable debug mode.
    # -g <locale_gen_name>      : Set locale-gen.
    # -i <inst_dir>             : Set install dir
    # -k <kernel config line>   : Set kernel name.
    # -o <os name>              : Set os name.
    # -p <password>             : Set password.
    # -s <shell>                : Set user shell.
    # -t                        : Set plymouth theme.
    # -u <username>             : Set live user name.
    # -x                        : Enable bash debug mode.
    # -z <locale_time>          : Set the time zone.
    # -l <locale_name>          : Set language.
    #
    # -j is obsolete in AlterISO3 and cannot be used.
    # -r is obsolete due to the removal of rebuild.
    # -k changed in AlterISO3 from passing kernel name to passing kernel configuration.

    # Generate options of customize_airootfs.sh.
    _airootfs_script_options=(-p "${password}" -k "${kernel} ${kernel_filename} ${kernel_mkinitcpio_profile}" -u "${username}" -o "${os_name}" -i "${install_dir}" -s "${usershell}" -a "${arch}" -g "${locale_gen_name}" -l "${locale_name}" -z "${locale_time}" -t "${theme_name}")
    [[ "${boot_splash}" = true ]] && _airootfs_script_options+=("-b")
    [[ "${debug}" = true       ]] && _airootfs_script_options+=("-d")
    [[ "${bash_debug}" = true  ]] && _airootfs_script_options+=("-x")

    _main_script="root/customize_airootfs.sh"

    _script_list=(
        "${pacstrap_dir}/root/customize_airootfs_${channel_name}.sh"
        "${pacstrap_dir}/root/customize_airootfs_${channel_name%.add}.sh"
    )

    for_module '_script_list+=("${pacstrap_dir}/root/customize_airootfs_{}.sh")'

    # Create script
    for _script in "${_script_list[@]}"; do
        if [[ -f "${_script}" ]]; then
            (echo -e "\n#--$(basename "${_script}")--#\n" && cat "${_script}")  >> "${pacstrap_dir}/${_main_script}"
            remove "${_script}"
        else
            _msg_debug "${_script} was not found."
        fi
    done

    _msg_info "Running ${_main_script} in '${pacstrap_dir}' chroot..."
    chmod 755 "${pacstrap_dir}/${_main_script}"
    chmod -f -- +x "${pacstrap_dir}/${_main_script}"
    cp "${pacstrap_dir}/${_main_script}" "${build_dir}/$(basename "${_main_script}")"
    # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
    env -u TMPDIR arch-chroot "${pacstrap_dir}" "/${_main_script}" "${_airootfs_script_options[@]}"
    rm -- "${pacstrap_dir}/root/customize_airootfs.sh"
    _msg_info "Done! customize_airootfs.sh run successfully."
}

_make_customize_bootstrap(){
    # backup airootfs.img for tarball
    _msg_debug "Tarball filename is ${tar_filename}"
    _msg_info "Copying airootfs.img ..."
    cp "${pacstrap_dir}.img" "${pacstrap_dir}.img.org"

    # Run script
    umount_work
    mount_airootfs
    if [[ -f "${pacstrap_dir}/root/optimize_for_tarball.sh" ]]; then 
        _chroot_run "bash" "/root/optimize_for_tarball.sh" -u "${username}"
        remove "${pacstrap_dir}/root/optimize_for_tarball.sh"
    fi
}


# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
_make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${pacstrap_dir}/etc/initcpio/hooks" "${pacstrap_dir}/etc/initcpio/install"

    for _hook in "archiso" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${pacstrap_dir}/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${pacstrap_dir}/etc/initcpio/install"
    done

    sed -i "s|%COWSPACE%|${cowspace}|g" "${pacstrap_dir}/etc/initcpio/hooks/archiso"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${pacstrap_dir}/etc/initcpio/install"
    cp "${script_path}/mkinitcpio/mkinitcpio-archiso.conf" "${pacstrap_dir}/etc/mkinitcpio-archiso.conf"
    [[ "${boot_splash}" = true ]] && cp "${script_path}/mkinitcpio/mkinitcpio-archiso-plymouth.conf" "${pacstrap_dir}/etc/mkinitcpio-archiso.conf"

    if [[ "${gpg_key}" ]]; then
        gpg --export "${gpg_key}" >"${build_dir}/gpgkey"
        exec 17<>"${build_dir}/gpgkey"
    fi

    _chroot_run mkinitcpio -c "/etc/mkinitcpio-archiso.conf" -k "/boot/${kernel_filename}" -g "/boot/archiso.img"

    [[ "${gpg_key}" ]] && exec 17<&-
    
    return 0
}


_make_version() {
    local _os_release

    _msg_info "Creating version files..."
    # Write version file to system installation dir
    rm -f -- "${pacstrap_dir}/version"
    printf '%s\n' "${iso_version}" > "${pacstrap_dir}/version"

    if [[ "${buildmode}" == @("iso"|"netboot") ]]; then
        install -d -m 0755 -- "${isofs_dir}/${install_dir}"
        # Write version file to ISO 9660
        printf '%s\n' "${iso_version}" > "${isofs_dir}/${install_dir}/version"
        # Write grubenv with version information to ISO 9660
        printf '%.1024s' "$(printf '# GRUB Environment Block\nNAME=%s\nVERSION=%s\n%s' \
            "${iso_name}" "${iso_version}" "$(printf '%0.1s' "#"{1..1024})")" \
            > "${isofs_dir}/${install_dir}/grubenv"
    fi

    # Append IMAGE_ID & IMAGE_VERSION to os-release
    _os_release="$(realpath -- "${pacstrap_dir}/etc/os-release")"
    if [[ ! -e "${pacstrap_dir}/etc/os-release" && -e "${pacstrap_dir}/usr/lib/os-release" ]]; then
        _os_release="$(realpath -- "${pacstrap_dir}/usr/lib/os-release")"
    fi
    if [[ "${_os_release}" != "${pacstrap_dir}"* ]]; then
        _msg_warning "os-release file '${_os_release}' is outside of valid path."
    else
        [[ ! -e "${_os_release}" ]] || sed -i '/^IMAGE_ID=/d;/^IMAGE_VERSION=/d' "${_os_release}"
        printf 'IMAGE_ID=%s\nIMAGE_VERSION=%s\n' "${iso_name}" "${iso_version}" >> "${_os_release}"
    fi
    _msg_info "Done!"
}

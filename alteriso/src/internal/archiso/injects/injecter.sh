#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034

override__make_customize_airootfs() {
    local passwd=()

    if [[ -e "${pacstrap_dir}/etc/passwd" ]]; then
        _msg_info "Copying /etc/skel/* to user homes..."
        while IFS=':' read -a passwd -r; do
            # Only operate on UIDs in range 1000–59999
            ((passwd[2] >= 1000 && passwd[2] < 60000)) || continue
            # Skip invalid home directories
            [[ "${passwd[5]}" == '/' ]] && continue
            [[ -z "${passwd[5]}" ]] && continue

            _msg_info "Setting up home directory for user: ${passwd[0]} (${passwd[5]})"

            # Prevent path traversal outside of $pacstrap_dir
            if [[ "$(realpath -q -- "${pacstrap_dir}${passwd[5]}")" == "${pacstrap_dir}"* ]]; then
                if [[ ! -d "${pacstrap_dir}${passwd[5]}" ]]; then
                    install -d -m 0750 -o "${passwd[2]}" -g "${passwd[3]}" -- "${pacstrap_dir}${passwd[5]}"
                fi
                cp -dRT --update=none --preserve=mode,timestamps,links -- "${pacstrap_dir}/etc/skel/." "${pacstrap_dir}${passwd[5]}"
                chmod -f 0750 -- "${pacstrap_dir}${passwd[5]}"
                chown -hR -- "${passwd[2]}:${passwd[3]}" "${pacstrap_dir}${passwd[5]}"
            else
                _msg_error "Failed to set permissions on '${pacstrap_dir}${passwd[5]}'. Outside of valid path." 1
            fi
        done <"${pacstrap_dir}/etc/passwd"
        _msg_info "Done!"
    fi

    if [[ -e "${pacstrap_dir}/root/customize_airootfs.sh" ]]; then
        _msg_info "Running customize_airootfs.sh in '${pacstrap_dir}' chroot..."
        # _msg_warning "customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version."
        chmod -f -- +x "${pacstrap_dir}/root/customize_airootfs.sh"
        # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
        eval -- env -u TMPDIR arch-chroot "${pacstrap_dir}" "/root/customize_airootfs.sh"
        rm -- "${pacstrap_dir}/root/customize_airootfs.sh"
        _msg_info "Done! customize_airootfs.sh run successfully."
    fi
}

# Make version file for alteriso
post__make_version+=(
    __alteriso_make_version
)
__alteriso_make_version() {
    local _version_file="$__alteriso_profile_dir/alteriso.json"
    if [[ -e $_version_file ]]; then
        install -Dm644 "$_version_file" "${isofs_dir}/${install_dir}/alteriso.json"
    fi

    if [[ "${buildmode}" == @("iso"|"netboot") ]]; then
        rm -f -- "${pacstrap_dir}/alteriso.json"
        install -Dm644 "$_version_file" "${isofs_dir}/${install_dir}/alteriso.json"

        install -d -m 0755 -- "${isofs_dir}/${install_dir}"
        install -Dm644 "$_version_file" "${isofs_dir}/${install_dir}/alteriso.json"
    elif [[ "${buildmode}" == 'bootstrap' ]]; then
        rm -f -- "${bootstrap_parent}/alteriso.json"
        install -Dm644 "$_version_file" "${bootstrap_parent}/alteriso.json"
    fi
}

# Inject pacman cache directory into pacman.conf
pre__make_pacman_conf+=(
    __alteriso_inject_cachedir
)
__alteriso_inject_cachedir() {
    [[ -n "${ALTERISO_PACMAN_CACHE-""}" ]] || return 0

    local __alteriso_cachedir="$ALTERISO_PACMAN_CACHE"
    local __alteriso_pacman_conf="$work_dir/alteriso_pacman.conf"

    pacman-conf -c "$pacman_conf" \
        | sed -e "s|^CacheDir = .*|CacheDir = $__alteriso_cachedir|" \
            >"$__alteriso_pacman_conf"
    pacman_conf="$__alteriso_pacman_conf"
}

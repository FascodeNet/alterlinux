#!/usr/bin/env bash
# shellcheck disable=SC2154

override__make_customize_airootfs() {
    local passwd=()

    if [[ -e "${profile}/airootfs/etc/passwd" ]]; then
        _msg_info "Copying /etc/skel/* to user homes..."
        while IFS=':' read -a passwd -r; do
            # Only operate on UIDs in range 1001–59999
            ((passwd[2] >= 1001 && passwd[2] < 60000)) || continue
            # Skip invalid home directories
            [[ "${passwd[5]}" == '/' ]] && continue
            [[ -z "${passwd[5]}" ]] && continue
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
        done <"${profile}/airootfs/etc/passwd"
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

_make_passwd() {
    local _username
    _username=$(__alteriso_profiledef | jq -r ".username")

    _msg_info "Setting up auto-login for user: $_username"

    passwd+=("${_username}:x:1000:1000:Live User:/home/${_username}:/bin/zsh")
    printf '%s\n' "${passwd[@]}" >> "${pacstrap_dir}/etc/passwd"
    # shellcheck disable=SC2034
    # file_permissions["/etc/passwd"]="0:0:644"
    _msg_info "Setting up user for auto-login: $_username"
}

pre__make_customize_airootfs() {
    _make_passwd
}

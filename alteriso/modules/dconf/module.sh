#!/usr/bin/env bash
# shellcheck disable=SC2154

# Profiles and modules ship keyfiles only; dconf reads the compiled databases.
__alteriso_dconf_update() {
    local _db
    for _db in "$pacstrap_dir"/etc/dconf/db/*.d; do
        [[ -d "$_db" ]] || return 0
        break
    done

    if [[ ! -x "$pacstrap_dir/usr/bin/dconf" ]]; then
        _msg_warning "dconf is not installed. Skipping database compilation."
        return 0
    fi

    _msg_info "Compiling dconf databases..."
    if ((EUID != 0)); then
        env -u TMPDIR arch-chroot -N "$pacstrap_dir" dconf update
    else
        env -u TMPDIR arch-chroot "$pacstrap_dir" dconf update
    fi
    _msg_info "Done!"
}

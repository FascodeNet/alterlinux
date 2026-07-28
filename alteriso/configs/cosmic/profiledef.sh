#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="alterlinux-cosmic"
iso_label="ALTER_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Alter Linux <https://fascode.net>"
iso_application="Alter Linux COSMIC Live/Rescue DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="alter"
buildmodes=('iso')
bootmodes=('bios.syslinux'
    'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
    ["/etc/shadow"]="0:0:400"
    ["/root"]="0:0:750"
    ["/root/.automated_script.sh"]="0:0:755"
    ["/root/.gnupg"]="0:0:700"
    ["/usr/local/bin/choose-mirror"]="0:0:755"
    ["/usr/local/bin/Installation_guide"]="0:0:755"
    ["/usr/local/bin/livecd-sound"]="0:0:755"
)

git_revision=${GIT_REVISION-"$(git rev-parse --short HEAD 2>/dev/null || true)"}
if [[ -n "$git_revision" ]]; then
    iso_version+="-$git_revision"
fi

post__make_customize_airootfs+=(__alteriso_cosmic_customize_airootfs)

# cosmic-greeter.toml is owned by cosmic-greeter, so it cannot be shipped from airootfs.
__alteriso_cosmic_greeter_autologin() {
    local _conf="${pacstrap_dir}/etc/greetd/cosmic-greeter.toml"
    [[ -e "$_conf" ]] || return 0
    printf '\n[initial_session]\ncommand = "cosmic-session"\nuser = "%s"\n' \
        "$(__alteriso_profiledef_username)" | _unshare tee -a "$_conf" >/dev/null
}

# cosmic-greeter.service conflicts with getty@tty1.service.
__alteriso_cosmic_disable_getty_autologin() {
    local _conf="${pacstrap_dir}/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    [[ -e "$_conf" ]] || return 0
    _unshare rm -f -- "$_conf"
}

__alteriso_cosmic_customize_airootfs() {
    __alteriso_cosmic_greeter_autologin
    __alteriso_cosmic_disable_getty_autologin
}

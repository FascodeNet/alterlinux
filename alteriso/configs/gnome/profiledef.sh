#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="alterlinux-gnome"
iso_label="ALTER_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Alter Linux <https://fascode.net>"
iso_application="Alter Linux GNOME Live/Rescue DVD"
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
    ["/root"]="0:0:750"
    ["/root/.automated_script.sh"]="0:0:755"
    ["/root/.gnupg"]="0:0:700"
)

git_revision=${GIT_REVISION-"$(git rev-parse --short HEAD 2>/dev/null || true)"}
if [[ -n "$git_revision" ]]; then
    iso_version+="-$git_revision"
fi

#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="alterlinux-nostalgia"
iso_label="ARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Arch Linux <https://archlinux.org>"
iso_application="Alter Linux Nostalgia (i486, non-PAE)"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="alternost"
buildmodes=('iso')
bootmodes=('bios.syslinux')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# LLM Modified: zstd decompresses several times faster than xz on a 486; 256K blocks cut per-read cost - Claude
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '256K')
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

# BIOS-only image: skip grub artifacts (/boot/grub/grubenv, loopback.cfg)
override__make_common_grubenv_and_loopbackcfg() { :; }

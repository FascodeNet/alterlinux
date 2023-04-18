#!/usr/bin/env bash
# shellcheck disable=all

iso_name="{{ .iso_name }}"
iso_label="{{ .iso_label }}"
iso_publisher="{{ .iso_publisher }}"
iso_application="{{ .iso_application }}"
iso_version="{{ .iso_version }}"
install_dir="{{ .install_dir }}"
{{ if not (bool .noiso) }}buildmodes=("iso"){{ end }}
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito')
{{ if not (bool .noefi) }}bootmodes+=('uefi-ia32.grub.esp' 'uefi-x64.grub.esp' 'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito'){{ end }}
arch="{{ .arch }}"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)

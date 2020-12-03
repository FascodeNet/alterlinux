#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="alterlinux-basic"
iso_label="ALTER_$(date +%Y%m)"
iso_publisher="Alter Linux <https://fascode.net/>"
iso_application="Alter Linux basic"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"

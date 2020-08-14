#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux"
iso_label="ARCH_$(date +%Y%m)"
iso_publisher="Arch Linux <https://www.archlinux.org>"
iso_application="Arch Linux Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=()
arch="x86_64"
pacman_conf="pacman.conf"

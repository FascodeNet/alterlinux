#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.


code="export QT_QPA_PLATFORMTHEME=qt5ct"
files=(
    "/etc/zsh/zshenv"
    "/etc/bash.bashrc"
    "/etc/skel/.profile"
    "/home/${username}/.profile"
)

for file in "${files[@]}"; do
    mkdir -p "$(dirname "${file}")"
    touch "${file}"
    echo "${code}" >> "${file}"
done

unset code files file

#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
set -e

build_username="pkgbuild"
pacman_debug=false
pacman_args=()
remove_list=()

_help() {
    echo "usage ${0} [option]"
    echo
    echo "Build and install PKGBUILD" 
    echo
    echo " General options:"
    echo "    -c                       Enable pacman debug message"
    echo "    -u [user]                Set the user name to build packages"
    echo "    -x                       Enable bash debug message"
    echo "    -h                       This help message"
}

while getopts "cu:xh" arg; do
    case "${arg}" in
        c) pacman_debug=true ;;
        u) build_username="${OPTARG}" ;;
        x) set -xv ;;
        h) 
            _help
            exit 0
            ;;
        *)
            _help
            exit 1
            ;;
    esac
done

shift "$((OPTIND - 1))"

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do echo "Removing ${_file}" >&2; rm -rf "${_file}"; done
}

# user_check <name>
function user_check () {
    if [[ ! -v 1 ]]; then return 2; fi
    getent passwd "${1}" > /dev/null
}

# 一般ユーザーで実行します
function run_user () {
    sudo -u "${build_username}" "${@}"
}

# 引数を確認
if [[ -z "${1}" ]]; then
    echo "Please specify the directory that contains PKGBUILD." >&2
    exit 1
else
    pkgbuild_dir="${1}"
fi

# Creating a user for makepkg
if ! user_check "${build_username}"; then
    useradd -m -d "${pkgbuild_dir}" "${build_username}"
fi
mkdir -p "${pkgbuild_dir}"
chmod 700 -R "${pkgbuild_dir}"
chown -R "${build_username}" "${pkgbuild_dir}"
echo "${build_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/pkgbuild"

# Setup keyring
pacman-key --init
pacman-key --populate

# Un comment the mirror list.
#sed -i "s/#Server/Server/g" "/etc/pacman.d/mirrorlist"

# Set pacman args
pacman_args=("--config" "/etc/alteriso-pacman.conf" "--noconfirm")
if [[ "${pacman_debug}" = true ]]; then
    pacman_args+=("--debug")
fi

# Update datebase
pacman -Syy "${pacman_args[@]}"

# Parse SRCINFO
cd "${pkgbuild_dir}"
readarray -t pkgbuild_dirs < <(ls "${pkgbuild_dir}" 2> /dev/null)
if (( "${#pkgbuild_dirs[@]}" != 0 )); then
    for _dir in "${pkgbuild_dirs[@]}"; do
        cd "${_dir}"
        readarray -t depends < <(source "${pkgbuild_dir}/${_dir}/PKGBUILD"; printf "%s\n" "${depends[@]}")
        readarray -t makedepends < <(source "${pkgbuild_dir}/${_dir}/PKGBUILD"; printf "%s\n" "${makedepends[@]}")
        if (( ${#depends[@]} + ${#makedepends[@]} != 0 )); then
            for _pkg in "${depends[@]}" "${makedepends[@]}"; do
                if pacman -Ssq "${_pkg}" | grep -x "${_pkg}" 1> /dev/null; then
                    pacman -S --asdeps --needed "${pacman_args[@]}" "${_pkg}"
                fi
            done
        fi
        run_user makepkg -fACcs --noconfirm --skippgpcheck
        for pkg in $(run_user makepkg -f --packagelist); do
            pacman --needed "${pacman_args[@]}" -U "${pkg}"
        done
        cd - >/dev/null
    done
fi


readarray -t -O "${#remove_list[@]}" remove_list < <(pacman -Qtdq) 
(( "${#remove_list[@]}" != 0 )) && pacman -Rsnc "${remove_list[@]}" "${pacman_args[@]}"

pacman -Sccc "${pacman_args[@]}"

# remove user and file
userdel "${build_username}"
remove "${pkgbuild_dir}"
remove "/etc/sudoers.d/pkgbuild"
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"

#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
#shellcheck disable=SC2001

set -e -u

aur_username="aurbuild"
pacman_debug=false
pacman_args=()
failedpkg=()
remove_list=()
aur_helper_depends=("go")
aur_helper_command="yay"
aur_helper_package="yay"
aur_helper_args=()
pkglist=()

trap 'exit 1' 1 2 3 15

_help() {
    echo "usage ${0} [option] [aur helper args] ..."
    echo
    echo "Install aur packages with ${aur_helper_command}" 
    echo
    echo " General options:"
    echo "    -a [command]             Set the command of aur helper"
    echo "    -c                       Enable pacman debug message"
    echo "    -e [pkg]                 Set the package name of aur helper"
    echo "    -d [pkg1,pkg2...]        Set the oackage of the depends of aur helper"
    echo "    -p [pkg1,pkg2...]        Set the AUR package to install"
    echo "    -u [user]                Set the user name to build packages"
    echo "    -x                       Enable bash debug message"
    echo "    -h                       This help message"
}

while getopts "a:cd:e:p:u:xh" arg; do
    case "${arg}" in
        a) aur_helper_command="${OPTARG}" ;;
        c) pacman_debug=true ;;
        e) aur_helper_package="${OPTARG}" ;;
        p) readarray -t pkglist < <(sed "s|,$||g" <<< "${OPTARG}" | tr "," "\n") ;;
        d) readarray -t aur_helper_depends < <(sed "s|,$||g" <<< "${OPTARG}" | tr "," "\n") ;;
        u) aur_username="${OPTARG}" ;;
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
aur_helper_args=("${@}")
eval set -- "${pkglist[@]}"

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do echo "Removing ${_file}" >&2; rm -rf "${_file}"; done
}

# user_check <name>
user_check () {
    if [[ ! -v 1 ]]; then return 2; fi
    getent passwd "${1}" > /dev/null
}

installpkg(){
    yes | sudo -u "${aur_username}" \
        "${aur_helper_command}" -S \
            --color always \
            --cachedir "/var/cache/pacman/pkg/" \
            "${pacman_args[@]}" \
            "${aur_helper_args[@]}" \
            "${@}" || true
}


#-- main funtions --#
prepare_env(){
    # Creating a aur user.
    if ! user_check "${aur_username}"; then
        useradd -m -d "/aurbuild_temp" "${aur_username}"
    fi
    mkdir -p "/aurbuild_temp"
    chmod 700 -R "/aurbuild_temp"
    chown "${aur_username}:${aur_username}" -R "/aurbuild_temp"
    echo "${aur_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"

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
}

install_aur_helper(){
    # Install
    if ! pacman -Qq "${aur_helper_package}" 1> /dev/null 2>&1; then
        _oldpwd="$(pwd)"

        # Install depends
        for _pkg in "${aur_helper_depends[@]}"; do
            if ! pacman -Qq "${_pkg}" > /dev/null 2>&1 | grep -q "${_pkg}"; then
                # --asdepsをつけているのでaur.shで削除される --neededをつけているので明示的にインストールされている場合削除されない
                pacman -S --asdeps --needed "${pacman_args[@]}" "${_pkg}"
                #remove_list+=("${_pkg}")
            fi
        done

        # Build
        sudo -u "${aur_username}" git clone "https://aur.archlinux.org/${aur_helper_package}.git" "/tmp/${aur_helper_package}"
        cd "/tmp/${aur_helper_package}"
        sudo -u "${aur_username}" makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm --syncdeps

        # Install
        for _pkg in $(cd "/tmp/${aur_helper_package}"; sudo -u "${aur_username}" makepkg --packagelist); do
            pacman "${pacman_args[@]}" -U "${_pkg}"
        done

        # Remove debtis
        cd ..
        remove "/tmp/${aur_helper_package}"
        cd "${_oldpwd}"
    fi

    if ! type -p "${aur_helper_command}" > /dev/null; then
        echo "Failed to install ${aur_helper_package}"
        exit 1
    fi
}

install_aur_pkgs(){
    # Update database
    pacman -Syy "${pacman_args[@]}"

    # Build and install
    chmod +s /usr/bin/sudo
    for _pkg in "${@}"; do
        pacman -Qq "${_pkg}" > /dev/null 2>&1  && continue
        installpkg "${_pkg}"

        if ! pacman -Qq "${_pkg}" > /dev/null 2>&1; then
            echo -e "\n[aur.sh] Failed to install ${_pkg}\n"
            failedpkg+=("${_pkg}")
        fi
    done

    # Reinstall failed package
    for _pkg in "${failedpkg[@]}"; do
        installpkg "${_pkg}"
        if ! pacman -Qq "${_pkg}" > /dev/null 2>&1; then
            echo -e "\n[aur.sh] Failed to install ${_pkg}\n"
            exit 1
        fi
    done
}

cleanup(){
    # Remove packages
    readarray -t -O "${#remove_list[@]}" remove_list < <(pacman -Qttdq)
    (( "${#remove_list[@]}" != 0 )) && pacman -Rsnc "${remove_list[@]}" "${pacman_args[@]}"

    # Clean up
    "${aur_helper_command}" -Sccc "${pacman_args[@]}" || true

    # remove user and file
    userdel "${aur_username}"
    remove /aurbuild_temp
    remove /etc/sudoers.d/aurbuild
    remove "/etc/alteriso-pacman.conf"
    remove "/var/cache/pacman/pkg/"
}


prepare_env
install_aur_helper
install_aur_pkgs "$@"
cleanup


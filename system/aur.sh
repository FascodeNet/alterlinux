#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
set -e -u

aur_username="aurbuild"
pacman_debug=false
pacman_args=()
failedpkg=()
remove_list=()
yay_depends=("go")

trap 'exit 1' 1 2 3 15

_help() {
    echo "usage ${0} [option]"
    echo
    echo "Install aur packages with yay" 
    echo
    echo " General options:"
    echo "    -d                       Enable pacman debug message"
    echo "    -u [user]                Set the user name to build packages"
    echo "    -x                       Enable bash debug message"
    echo "    -h                       This help message"
}

while getopts "du:xh" arg; do
    case "${arg}" in
        d) pacman_debug=true ;;
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

# Install yay
if ! pacman -Qq yay 1> /dev/null 2>&1; then
    # Update database
    _oldpwd="$(pwd)"
    pacman -Syy "${pacman_args[@]}"

    # Install depends
    for _pkg in "${yay_depends[@]}"; do
        if ! pacman -Qq "${_pkg}" | grep -q "${_pkg}"; then
            pacman -S --asdeps --needed "${pacman_args[@]}" "${_pkg}"
            remove_list+=("${_pkg}")
        fi
    done

    # Build yay
    sudo -u "${aur_username}" git clone "https://aur.archlinux.org/yay.git" "/tmp/yay"
    cd "/tmp/yay"
    sudo -u "${aur_username}" makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm

    # Install yay
    for _pkg in $(sudo -u "${aur_username}" makepkg --packagelist); do
        pacman "${pacman_args[@]}" -U "${_pkg}"
    done

    # Remove debtis
    cd ..
    remove "/tmp/yay"
    cd "${_oldpwd}"
fi

if ! type -p yay > /dev/null; then
    echo "Failed to install yay"
    exit 1
fi

installpkg(){
    yes | sudo -u "${aur_username}" \
        yay -Sy \
            --mflags "-AcC" \
            --aur \
            --nocleanmenu \
            --nodiffmenu \
            --noeditmenu \
            --noupgrademenu \
            --noprovides \
            --removemake \
            --useask \
            --color always \
            --mflags "--skippgpcheck" \
            "${pacman_args[@]}" \
            --cachedir "/var/cache/pacman/pkg/" \
            "${@}" || true
}


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

# Remove packages
readarray -t -O "${#remove_list[@]}" remove_list < <(pacman -Qttdq)
(( "${#remove_list[@]}" != 0 )) && pacman -Rsnc "${remove_list[@]}" "${pacman_args[@]}"

# Clean up
yay -Sccc "${pacman_args[@]}"

# remove user and file
userdel "${aur_username}"
remove /aurbuild_temp
remove /etc/sudoers.d/aurbuild
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"

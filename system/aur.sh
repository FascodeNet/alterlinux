#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
#shellcheck disable=SC2001

#-- Initilize --#
set -e -u
trap 'exit 1' 1 2 3 15

#-- Set variables --#
aur_username="aurbuild"
pacman_debug=false
pacman_args=()
failedpkg=()
remove_list=()
pkglist=()
builddir="/aurbuild_temp"

#-- Load shell library --#
source /dev/stdin < <(curl -sL https://raw.githubusercontent.com/Hayao0819/FasBashLib/build-dev/fasbashlib.sh)

#-- Functions --#
# CheckUser <name>
check_user () {
    getent passwd "${1}" > /dev/null
}

_help() {
    echo "usage ${0} [option]"
    echo
    echo "Install aur packages"
    echo
    echo " General options:"
    echo "    -c                       Enable pacman debug message"
    echo "    -p [pkg1,pkg2...]        Set the AUR package to install"
    echo "    -u [user]                Set the user name to build packages"
    echo "    -x                       Enable bash debug message"
    echo "    -h | --help              This help message"
}

# Create user to build and setup pacman key
prepare_env(){
    # Creating a aur user.
    check_user "${aur_username}" || useradd -m -d "${builddir}" "${aur_username}"
    mkdir -p "${builddir}"
    chmod 700 -R "${builddir}"
    chown "${aur_username}:${aur_username}" -R "${builddir}"
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

    # Create dir
    mkdir -p "$builddir/Build" "$builddir/SnapShot"
}

# Install AUR package
# install_aur_pkg <pkg>
install_aur_pkg(){
    local _Json _PkgName _SnapShotURL _SnapShot
    _Json="$(GetRawAurInfo "$1")"

    # Check JSON
    CheckAurJson <<< "$_Json" > /dev/null || {
        MsgErr "No $1 package is found."
        return 1
    }
    _Json="$(CheckAurJson <<< "$_Json")"

    # Get PkgBuild
    _SnapShotURL="$(GetAurURLPath <<< "$_Json")"
    _SnapShot="${builddir}/SnapShot/$(basename "$_SnapShotURL")"
    curl -sL -o "$_SnapShot" "https://aur.archlinux.org/$_SnapShotURL"
    tar -xv -f "${_SnapShot}" -C "${builddir}/build/" > /dev/null 2>&1

    # Get depends
    local _Depends=() _RepoPkgs=()
    ArrayAppend _Depends < <(GetSrcInfoValue depends < ./.SRCINFO)
    readarray -t _RepoPkgs < <(GetPacmanRepoPkgList)    
    for _Pkg in "${_Depends[@]}" ; do
        ArrayAppend _AURDepend < <(ArrayIncludes _RepoPkgs "$_Pkg" || echo "$_Pkg")
    done
    PrintEvalArray _AURDepend | ForEach install_aur_pkg "{}"

    # Create Pkg
    cd "$builddir/build/${1}"
    sudo -u "${aur_username}" makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm --syncdeps

    # Install
    for _pkg in $(cd "$builddir/build/${1}"; sudo -u "${aur_username}" makepkg --packagelist); do
        pacman "${pacman_args[@]}" -U "${_pkg}"
    done

    # Check
    if ! type -p "${1}" > /dev/null; then
        echo "[aur.sh] Failed to install ${1}"
        return 1
    fi
}

run_install(){
    # Install
    PrintEvalArray pkglist | ForEach eval 'install_aur_pkg "{}" || failedpkg+=("{}")'

    # Retry
    PrintEvalArray failedpkg | ForEach eval 'install_aur_pkg {} || exit 1'
}

cleanup(){
    # Remove packages
    readarray -t -O "${#remove_list[@]}" remove_list < <(pacman -Qttdq)
    (( "${#remove_list[@]}" != 0 )) && pacman -Rsnc "${remove_list[@]}" "${pacman_args[@]}"

    # Clean up
    "${aur_helper_command}" -Sccc "${pacman_args[@]}"

    # remove user and file
    userdel "${aur_username}"
    remove "$builddir"
    remove /etc/sudoers.d/aurbuild
    remove "/etc/alteriso-pacman.conf"
    remove "/var/cache/pacman/pkg/"
}

#-- ParseArgs --#
ParseArg LONG="help" SHORT="cp:u:xh" -- "$@" || exit 1
eval set -- "${OPTRET[@]}"
unset OPTRET
while true; do
    case "$1" in
        "-c")
            pacman_debug=true
            shift 1
            ;;
        "-p")
            ArrayAppend pkglist < <(tr "," "\n" <<< "$2" | sed "/^$/d" | RemoveBlank)
            shift 2
            ;;
        "-u")
            aur_username="$2"
            shift 2
            ;;
        "x")
            set -xv
            shift 1
            ;;
        "-h" | "--help")
            _help
            exit 0
            ;;
        "--")
            shift 1
            break
            ;;
    esac
done

#-- Run --#
prepare_env
run_install
cleanup

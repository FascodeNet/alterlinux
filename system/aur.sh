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
set -e -u -E
trap 'exit 1' 1 2 3 15
umask 022

#-- Set variables --#
aur_username="aurbuild"
pacman_debug=false
pacman_args=()
failedpkg=()
remove_list=()
pkglist=()
builddir="/aurbuild_temp"

export PACMAN_CONF="/etc/alteriso-pacman.conf"

#-- Load shell library --#
source "/dev/stdin" < <(curl -sL "https://raw.githubusercontent.com/Hayao0819/FasBashLib/build-dev/fasbashlib.sh")

RunPacmanKey(){
    pacman-key --config "${PACMAN_CONF-"/etc/pacman.conf"}" "$@"
}

#-- Functions --#
# CheckUser <name>
check_user () {
    getent passwd "${1}" > /dev/null
}


remove() {
    echo "Removing ${*}" >&2
    rm -rf "${@}"
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
    chmod 777 -R "${builddir}"
    chown "${aur_username}:${aur_username}" -R "${builddir}"
    echo "${aur_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"
    curl -sL "https://raw.githubusercontent.com/Hayao0819/FasBashLib/build-dev/fasbashlib.sh" > "$builddir/fasbashlib.sh"

    # Setup keyring
    RunPacmanKey --init
    RunPacmanKey --populate

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
    Pm.CheckPkg "$1" && return 0

    #source "$builddir/fasbashlib.sh"

    sudo rm -rf "/var/lib/pacman/db.lck"
    _Json="$(Aur.GetRawInfo "$1")"

    # Check JSON
    Aur.CheckJson <<< "$_Json" > /dev/null || {
        Msg.Err "No $1 package is found."
        return 1
    }
    _Json="$(Aur.CheckJson <<< "$_Json")"

    # Get PkgBuild
    _SnapShotURL="$(Aur.GetURLPath <<< "$_Json")"
    _SnapShot="${builddir}/SnapShot/$(basename "$_SnapShotURL")"
    sudo -u "${aur_username}" curl -L -o "$_SnapShot" "https://aur.archlinux.org/$_SnapShotURL"
    sudo -u "${aur_username}" tar -xv -f "${_SnapShot}" -C "${builddir}/Build/"

    # Move to PKGBUILD dir
    cd "$builddir/Build/${1}"

    # Get depends
    local _Depends=() _RepoPkgs=() _Arch
    _Arch="$(Pm.GetConfig Architecture)"

    ArrayAppend _Depends < <(SrcInfo.GetValue "depends" "$1" "$_Arch" < ./.SRCINFO | Pm.GetName)
    ArrayAppend _Depends < <(SrcInfo.GetValue "makedepends" "$1" "$_Arch" < ./.SRCINFO | Pm.GetName)
    readarray -t _RepoPkgs < <(Pm.GetRepoPkgList)
    _AURDepend=() _RepoDepend=()
    for _Pkg in "${_Depends[@]}" ; do
        if ArrayIncludes _RepoPkgs "$_Pkg"; then
            echo "Found repo depend: $_Pkg"
            ArrayAppend _RepoDepend <<< "$_Pkg"
        else
            echo "Found AUR depend: $_Pkg"
            ArrayAppend _AURDepend <<< "$_Pkg"
        fi
    done
    PrintEvalArray _RepoDepend | ForEach pacman -S --asdeps --needed "${pacman_args[@]}" "{}"
    PrintEvalArray _AURDepend | ForEach install_aur_pkg "{}"

    # Create Pkg
    sudo -u "${aur_username}" makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm --syncdeps
    #makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm --syncdeps

    # Install
    for _pkg in $(cd "$builddir/Build/${1}"; sudo -u "${aur_username}" makepkg --packagelist); do
        pacman "${pacman_args[@]}" -U "${_pkg}"
    done

    # Check
    if ! CheckPacmanPkg "${1}" > /dev/null; then
        echo "[aur.sh] Failed to install ${1}"
        exit 1
    fi
}

run_install(){
    # Install
    #export -f install_aur_pkg
    while read -r _Pkg; do
        #su "${aur_username}" -c install_aur_pkg "$_Pkg" || failedpkg+=("$_Pkg")
        install_aur_pkg "$_Pkg" || failedpkg+=("$_Pkg")
    done < <(PrintEvalArray pkglist)

    # Retry
    while read -r _Pkg; do
        install_aur_pkg "$_Pkg" || exit 1
    done < <(PrintEvalArray failedpkg)
}

cleanup(){
    # Remove packages
    readarray -t -O "${#remove_list[@]}" remove_list < <(pacman -Qttdq)
    (( "${#remove_list[@]}" != 0 )) && pacman -Rsnc "${remove_list[@]}" "${pacman_args[@]}"

    # Clean up
    RunPacman -Sccc "${pacman_args[@]}"

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
        "-x")
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
        *)
            MsgErr "Unknown option: ${1}"
            exit 1
            ;;
    esac
done

#-- Run --#
prepare_env
run_install
cleanup

#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# build.sh
#
# The main script that runs the build
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Control the environment
umask 0022
export LC_ALL="C"
[[ -v SOURCE_DATE_EPOCH ]] || printf -v SOURCE_DATE_EPOCH '%(%s)T' -1
export SOURCE_DATE_EPOCH
set -E

# Internal config
# Do not change these values.
script_path="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
defaultconfig="${script_path}/default.conf"
tools_dir="${script_path}/tools" module_dir="${script_path}/modules"
customized_username=false customized_password=false customized_kernel=false customized_logpath=false
pkglist_args=() makepkg_script_args=() modules=() norepopkg=()
rerun=false
DEFAULT_ARGUMENT="" ARGUMENT=("${@}")
alteriso_version=(3.0 3.1 4.0)
use_bootloader_type="nosplash"
not_use_bootloader_type="splash"


#-- AlterISO 4.0 Variables --#
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito')
buildmodes=("iso") # buildmodes=("iso" "netboot" "bootstrap")
pacman_conf="/etc/pacman.conf"
airootfs_image_type="squashfs"
declare -A file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
quiet=n
app_name="AlterISO"
sign_netboot_artifacts=""
cert_list=()
# adapted from GRUB_EARLY_INITRD_LINUX_STOCK in https://git.savannah.gnu.org/cgit/grub.git/tree/util/grub-mkconfig.in
readonly ucodes=('intel-uc.img' 'intel-ucode.img' 'amd-uc.img' 'amd-ucode.img' 'early_ucode.cpio' 'microcode.cpio')

# Load config file
[[ ! -f "${defaultconfig}" ]] && "${tools_dir}/msg.sh" -a 'build.sh' error "${defaultconfig} was not found." && exit 1
for config in "${defaultconfig}" "${script_path}/custom.conf" "${script_path}/lib/"*".sh"; do
    [[ -e "${config}" ]] && source "${config}" && loaded_files+=("${config}")
done

# Message common function
# _msg_common [type] [-n] [string]
_msg_common(){
    local _msg_opts=("-a" "build.sh") _type="${1}" && shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${msgdebug}" = true ]] && _msg_opts+=("-x")
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    #"${tools_dir}/vlang/msg/msg"  "${_msg_opts[@]}"
    "${tools_dir}/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
_msg_info() { _msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
_msg_warn() { _msg_common warn "${@}"; }
_msg_warning() { _msg_warn "${@}"; }

# Show an debug message
# ${1}: message string
_msg_debug() { 
    [[ "${debug}" = true ]] && _msg_common debug "${@}" || return 0
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    _msg_common error "${1}"
    { [[ -n "${2:-""}" ]] && (( "${2}" > 0 )); } && exit "${2}" || return 0
}

#-- Compile V Tools --#
while read -r _dir; do
    if [[ -e "$_dir/main.v" ]]; then
        v -o "$_dir/$(basename "$_dir")" "$_dir/main.v"
    fi
done < <(find "${tools_dir}/vlang" -mindepth 1 -maxdepth 1 -type d)
unset _dir

#-- AlterISO 3.2 functions --#
# Build confirm
_build_confirm() {
    if [[ "${noconfirm}" = false ]]; then
        echo -e "\nPress Enter to continue or Ctrl + C to cancel."
        read -r
    fi
    trap HUP INT QUIT TERM
    trap 'umount_trap' HUP INT QUIT TERM
    trap 'error_exit_trap $LINENO' ERR
    return 0
}

# Shows configuration options.
_show_config() {
    local build_date
    printf -v build_date '%(%FT%R%z)T' "${SOURCE_DATE_EPOCH}"
    _msg_info "${app_name} configuration settings"
    _msg_info "             Architecture:   ${arch}"
    _msg_info "        Working directory:   ${work_dir}"
    _msg_info "   Installation directory:   ${install_dir}"
    _msg_info "               Build date:   ${build_date}"
    _msg_info "         Output directory:   ${out_dir}"
    _msg_info "       Current build mode:   ${buildmode}"
    _msg_info "              Build modes:   ${buildmodes[*]}"
    _msg_info "                  GPG key:   ${gpg_key:-None}"
    _msg_info "               GPG signer:   ${gpg_sender:-None}"
    _msg_info "Code signing certificates:   ${cert_list[*]:-None}"
    _msg_info "                  Profile:   ${channel_name}"
    _msg_info "Pacman configuration file:   ${pacman_conf}"
    _msg_info "          Image file name:   ${image_name:-None}"
    _msg_info "         ISO volume label:   ${iso_label}"
    _msg_info "            ISO publisher:   ${iso_publisher}"
    _msg_info "          ISO application:   ${iso_application}"
    _msg_info "               Boot modes:   ${bootmodes[*]:-None}"
    _msg_info "                 Plymouth:   ${boot_splash}"
    _msg_info "           Plymouth theme:   ${theme_name}"
    _msg_info "                 Language:   ${locale_name}"
    
    _build_confirm
}




build_config(){
    _make_profiledef
    _make_pacman_conf
    _make_packages
    _make_aur_packages
    _make_bootstrap_packages
    _make_syslinux
    _make_grub
    _make_efiboot
    _make_alteriso
    _make_airootfs
}

# Parse options
ARGUMENT=("${DEFAULT_ARGUMENT[@]}" "${@}") OPTS=("a:" "b" "c:" "d" "e" "g:" "h" "j" "k:" "l:" "o:" "p:" "r" "t:" "u:" "w:" "x") OPTL=("arch:" "boot-splash" "comp-type:" "debug" "cleaning" "cleanup" "gpgkey:" "help" "lang:" "japanese" "kernel:" "out:" "password:" "comp-opts:" "user:" "work:" "bash-debug" "nocolor" "noconfirm" "nodepend" "gitversion" "msgdebug" "noloopmod" "tarball" "noiso" "noaur" "nochkver" "channellist" "config:" "noefi" "nodebug" "nosigcheck" "normwork" "log" "logpath:" "nolog" "nopkgbuild" "pacman-debug" "confirm" "add-module:" "nogitversion" "cowspace:" "rerun" "depend" "loopmod" "cert:")
GETOPT=(-o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" -- "${ARGUMENT[@]}")
getopt -Q "${GETOPT[@]}" || exit 1 # 引数エラー判定
readarray -t OPT < <(getopt "${GETOPT[@]}") # 配列に代入

eval set -- "${OPT[@]}"
_msg_debug "Argument: ${OPT[*]}"
unset OPT OPTS OPTL DEFAULT_ARGUMENT GETOPT

while true; do
    case "${1}" in
        -c | --comp-type)
            case "${2}" in
                "gzip" | "lzma" | "lzo" | "lz4" | "xz" | "zstd") sfs_comp="${2}" ;;
                *) _msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        -j | --japanese)
            _msg_error "This option is obsolete in AlterISO 3. To use Japanese, use \"-l ja\"." "1"
            ;;
        -k | --kernel)
            customized_kernel=true kernel="${2}"
            shift 2
            ;;
        -p | --password)
            customized_password=true password="${2}"
            shift 2
            ;;
        -t | --comp-opts)
            if [[ "${2}" = "reset" ]]; then
                sfs_comp_opt=()
            else
                IFS=" " read -r -a sfs_comp_opt <<< "${2}"
            fi
            shift 2
            ;;
        -u | --user)
            customized_username=true
            username="$(echo -n "${2}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --nodebug)
            debug=false msgdebug=false bash_debug=false
            shift 1
            ;;
        --logpath)
            logging="${2}" customized_logpath=true
            shift 2
            ;;
        --add-module)
            readarray -t -O "${#additional_modules[@]}" additional_modules < <(echo "${2}" | tr "," "\n")
            _msg_debug "Added modules: ${additional_modules[*]}"
            shift 2
            ;;
        --cert)
            sign_netboot_artifacts="y"
            IFS=" " read -a -r override_cert_list <<< "${2}"
            cert_list+=("${override_cert_list[@]}")
            unset override_cert_list
            shift 2
            ;;
        -g | --gpgkey               ) gpg_key="${2}"           && shift 2 ;;
        -h | --help                 ) _usage 0                      ;;
        -a | --arch                 ) arch="${2}"              && shift 2 ;;
        -d | --debug                ) debug=true               && shift 1 ;;
        -e | --cleaning | --cleanup ) cleaning=true            && shift 1 ;;
        -b | --boot-splash          ) boot_splash=true         && shift 1 ;;
        -l | --lang                 ) locale_name="${2}"       && shift 2 ;;
        -o | --out                  ) out_dir="${2}"           && shift 2 ;;
        -r | --tarball              ) tarball=true             && shift 1 ;;
        -w | --work                 ) work_dir="${2}"          && shift 2 ;;
        -x | --bash-debug           ) bash_debug=true          && shift 1 ;;
        --gitversion                ) gitversion=true          && shift 1 ;;
        --noconfirm                 ) noconfirm=true           && shift 1 ;;
        --confirm                   ) noconfirm=false          && shift 1 ;;
        --nodepend                  ) nodepend=true            && shift 1 ;;
        --nocolor                   ) nocolor=true             && shift 1 ;;
        --msgdebug                  ) msgdebug=true            && shift 1 ;;
        --noloopmod                 ) noloopmod=true           && shift 1 ;;
        --noiso                     ) noiso=true               && shift 1 ;;
        --noaur                     ) noaur=true               && shift 1 ;;
        --nochkver                  ) nochkver=true            && shift 1 ;;
        --noefi                     ) noefi=true               && shift 1 ;;
        --channellist               ) _channel_name_full_list  && exit  0 ;;
        --config                    ) source "${2}"            ;  shift 2 ;;
        --pacman-debug              ) pacman_debug=true        && shift 1 ;;
        --nosigcheck                ) nosigcheck=true          && shift 1 ;;
        --normwork                  ) normwork=true            && shift 1 ;;
        --log                       ) logging=true             && shift 1 ;;
        --nolog                     ) logging=false            && shift 1 ;;
        --nopkgbuild                ) nopkgbuild=true          && shift 1 ;;
        --nogitversion              ) gitversion=false         && shift 1 ;;
        --cowspace                  ) cowspace="${2}"          && shift 2 ;;
        --rerun                     ) rerun=true               && shift 1 ;;
        --depend                    ) nodepend=false           && shift 1 ;;
        --loopmod                   ) noloopmod=false          && shift 1 ;;
        --                          ) shift 1                  && break   ;;
        *)
            _msg_error "Argument exception error '${1}'"
            _msg_error "Please report this error to the developer." 1
            ;;
    esac
done


# Show config message
_msg_debug "Use the default configuration file (${defaultconfig})."
[[ -f "${script_path}/custom.conf" ]] && _msg_debug "The default settings have been overridden by custom.conf"

# Debug mode
[[ "${bash_debug}" = true ]] && set -x -v

# Check for a valid channel name
if [[ -n "${1+SET}" ]]; then
    _msg_debug "Channel check status is $(_channel_check "${1}" >/dev/null ; printf "%d" "${?}")"
    case "$(_channel_check "${1}" >/dev/null ; printf "%d" "${?}")" in
        "2")
            _msg_error "Invalid channel ${1}" "1"
            ;;
        "1" | "3")
            channel_dir="${1}"
            channel_name="$(basename "${1}")"
            ;;
        "0")
            channel_dir="$(_channel_check "${1}")"
            channel_name="${1}"
            ;;
    esac
else
    channel_dir="${script_path}/channels/${channel_name}"
fi

if (( EUID != 0 )); then
    _msg_warn "This script must be run as root." >&2
    _msg_warn "Re-run 'sudo ${0} ${ARGUMENT[*]}'"
    sudo "${0}" "${ARGUMENT[@]}" --rerun
    exit "${?}"
fi

# Check architecture for each channel
_channel_check_arch "${channel_dir}" || _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"

# Set vars
gitrev="$(cd "${script_path}"; git rev-parse --short HEAD)"


# Create dir
mkdir -p "$out_dir"
_msg_debug "out_dir is $out_dir"
out_dir="$(realpath "$out_dir")"

# Set for special channels
if [[ "${channel_name}" = "clean" ]]; then
   _run_cleansh
    exit 0
fi

# Check channel version
_msg_debug "channel path is ${channel_dir}"
if ! _channel_check_version "${channel_dir}"; then
    _msg_error "This channel does not support Alter ISO 3."
    if [[ -d "${script_path}/.git" ]]; then
        _msg_error "Please run \"git checkout alteriso-2\"" "1"
    else
        _msg_error "Please download old version here.\nhttps://github.com/FascodeNet/alterlinux/releases" "1"
    fi
fi

prepare_env
prepare_build
build_config

[[ "${cleaning}" = true ]] || true && _run_cleansh

exit

# vim:ts=4:sw=4:et:

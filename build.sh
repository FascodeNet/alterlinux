#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#
# build.sh
#
# The main script that runs the build
#

set -eu

# Internal config
# Do not change these values.
script_path="$(readlink -f ${0%/*})"
defaultconfig="${script_path}/default.conf"
rebuild=false
customized_username=false

# Load config file
if [[ -f "${defaultconfig}" ]]; then
    source "${defaultconfig}"
else
    echo "${defaultconfig} was not found."
    exit 1
fi

umask 0022

# Color echo
# usage: echo_color -b <backcolor> -t <textcolor> -d <decoration> [Text]
#
# Text Color
# 30 => Black
# 31 => Red
# 32 => Green
# 33 => Yellow
# 34 => Blue
# 35 => Magenta
# 36 => Cyan
# 37 => White
#
# Background color
# 40 => Black
# 41 => Red
# 42 => Green
# 43 => Yellow
# 44 => Blue
# 45 => Magenta
# 46 => Cyan
# 47 => White
#
# Text decoration
# You can specify multiple decorations with ;.
# 0 => All attributs off (ノーマル)
# 1 => Bold on (太字)
# 4 => Underscore (下線)
# 5 => Blink on (点滅)
# 7 => Reverse video on (色反転)
# 8 => Concealed on

echo_color() {
    local backcolor textcolor decotypes echo_opts arg OPTIND OPT
    echo_opts="-e"
    while getopts 'b:t:d:n' arg; do
        case "${arg}" in
            b) backcolor="${OPTARG}" ;;
            t) textcolor="${OPTARG}" ;;
            d) decotypes="${OPTARG}" ;;
            n) echo_opts="-n -e"     ;;
        esac
    done
    shift $((OPTIND - 1))
    if [[ "${nocolor}" = false ]]; then
        echo ${echo_opts} "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${*}\e[m"
    else
        echo ${echo_opts} "${@}"
    fi
}


# Show an INFO message
# $1: message string
_msg_info() {
    if [[ "${msgdebug}" = false ]]; then
        set +xv
    else
        set -xv
    fi
    local echo_opts="-e" arg OPTIND OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[build.sh]')    $( echo_color -t '32' 'Info') ${*}"
    if [[ "${bash_debug}" = true ]]; then
        set -xv
    else
        set +xv
    fi
}


# Show an Warning message
# $1: message string
_msg_warn() {
    if [[ "${msgdebug}" = false ]]; then
        set +xv
    else
        set -xv
    fi
    local echo_opts="-e" arg OPTIND OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[build.sh]') $( echo_color -t '33' 'Warning') ${*}" >&2
    if [[ "${bash_debug}" = true ]]; then
        set -xv
    else
        set +xv
    fi
}


# Show an debug message
# $1: message string
_msg_debug() {
    if [[ "${msgdebug}" = false ]]; then
        set +xv
    else
        set -xv
    fi
    local echo_opts="-e" arg OPTIND OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    if [[ ${debug} = true ]]; then
        echo ${echo_opts} "$( echo_color -t '36' '[build.sh]')   $( echo_color -t '35' 'Debug') ${*}"
    fi
    if [[ "${bash_debug}" = true ]]; then
        set -xv
    else
        set +xv
    fi
}


# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    if [[ "${msgdebug}" = false ]]; then
        set +xv
    else
        set -xv
    fi
    local echo_opts="-e" arg OPTIND OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[build.sh]')   $( echo_color -t '31' 'Error') ${1}" >&2
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
    if [[ "${bash_debug}" = true ]]; then
        set -xv
    else
        set +xv
    fi
}


_usage () {
    echo "usage ${0} [options] [channel]"
    echo
    echo "A channel is a profile of AlterISO settings."
    echo
    echo " General options:"
    echo
    echo "    -b | --boot-splash           Enable boot splash"
    echo "    -l | --cleanup               Enable post-build cleaning."
    echo "    -h | --help                  This help message and exit."
    echo
    echo "    -a | --arch <arch>           Set iso architecture."
    echo "                                  Default: ${arch}"
    echo "    -c | --comp-type <comp_type> Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)"
    echo "                                  Default: ${sfs_comp}"
    echo "    -g | --lang <lang>           Specifies the default language for the live environment."
    echo "                                  Default: ${locale_name}"
    echo "    -k | --kernel <kernel>       Set special kernel type.See below for available kernels."
    echo "                                  Default: ${kernel}"
    echo "    -o | --out <out_dir>         Set the output directory"
    echo "                                  Default: ${out_dir}"
    echo "    -p | --password <password>   Set a live user password"
    echo "                                  Default: ${password}"
    echo "    -t | --comp-opts <options>   Set compressor-specific options."
    echo "                                  Default: empty"
    echo "    -u | --user <username>       Set user name."
    echo "                                  Default: ${username}"
    echo "    -w | --work <work_dir>       Set the working directory"
    echo "                                  Default: ${work_dir}"
    echo

    local blank="33" arch lang list _locale_name_list kernel

    echo " Language for each architecture:"
    for list in ${script_path}/system/locale-* ; do
        arch="${list#${script_path}/system/locale-}"
        echo -n "    ${arch}"
        for i in $( seq 1 $(( ${blank} - 4 - ${#arch} )) ); do
            echo -ne " "
        done
        _locale_name_list=$(cat ${list} | grep -h -v ^'#' | awk '{print $1}')
        for lang in ${_locale_name_list[@]};do
            echo -n "${lang} "
        done
        echo
    done

    echo
    echo " Kernel for each architecture:"
    for list in ${script_path}/system/kernel-* ; do
        arch="${list#${script_path}/system/kernel-}"
        echo -n "    ${arch} "
        for i in $( seq 1 $(( ${blank} - 5 - ${#arch} )) ); do
            echo -ne " "
        done
        for kernel in $(grep -h -v ^'#' ${list} | awk '{print $1}'); do
            echo -n "${kernel} "
        done
        echo
    done

    echo
    echo " Channel:"
    for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9}'); do
        if [[ -n $(ls "${script_path}"/channels/${i}) ]] && [[ ! ${i} = "share" ]] && [[ "$(cat "${script_path}/channels/${i}/alteriso" 2> /dev/null)" = "alteriso=3" ]]; then
            if [[ $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                channel_list="${channel_list[@]} ${i}"
            elif [[ ! -d "${script_path}/channels/${i}.add" ]]; then
                channel_list="${channel_list[@]} ${i}"
            fi
        fi
    done
    channel_list="${channel_list[@]} rebuild"
    for _channel in ${channel_list[@]}; do
        if [[ -f "${script_path}/channels/${_channel}/description.txt" ]]; then
            description=$(cat "${script_path}/channels/${_channel}/description.txt")
        elif [[ ${_channel} = "rebuild" ]]; then
            description="Build from the point where it left off using the previous build settings."
        else
            description="This channel does not have a description.txt."
        fi
        if [[ $(echo "${_channel}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
            echo -ne "    $(echo ${_channel} | sed 's/\.[^\.]*$//')"
            for i in $( seq 1 $(( ${blank} - ${#_channel} )) ); do
                echo -ne " "
            done
        else
            echo -ne "    ${_channel}"
            for i in $( seq 1 $(( ${blank} - 4 - ${#_channel} )) ); do
                echo -ne " "
            done
        fi
        echo -ne "${description}\n"
    done

    echo
    echo " Debug options: Please use at your own risk."
    echo "    -d | --debug                 Enable debug messages."
    echo "    -x | --bash-debug            Enable bash debug mode.(set -xv)"
    echo "         --gitversion            Add Git commit hash to image file version"
    echo "         --msgdebug              Enables output debugging."
    echo "         --noaur                 No build and install AUR packages."
    echo "         --nocolor               No output colored output."
    echo "         --noconfirm             No check the settings before building."
    echo "         --nochkver              NO check the version of the channel."
    echo "         --noloopmod             No check and load kernel module automatically."
    echo "         --nodepend              No check package dependencies before building."
    echo "         --noiso                 No build iso image. (Use with --tarball)"
    echo "         --shmkalteriso          Use the shell script version of mkalteriso."
    if [[ -n "${1:-}" ]]; then
        exit "${1}"
    fi
}


# Unmount chroot dir
umount_chroot () {
    local mount
    for mount in $(mount | awk '{print $3}' | grep $(realpath ${work_dir}) | tac); do
        _msg_info "Unmounting ${mount}"
        umount -lf "${mount}"
    done
}

# Helper function to run make_*() only one time.
run_once() {
    if [[ ! -e "${work_dir}/lockfile/build.${1}_${arch}" ]]; then
        umount_chroot
        _msg_debug "Running $1 ..."
        "$1"
        mkdir -p "${work_dir}/lockfile" 
        touch "${work_dir}/lockfile/build.${1}_${arch}"
        umount_chroot
    else
        _msg_debug "Skipped because ${1} has already been executed."
    fi
}

# rm helper
# Delete the file if it exists.
# For directories, rm -rf is used.
# If the file does not exist, skip it.
# remove <file> <file> ...
remove() {
    local _list=($(echo "$@")) _file
    for _file in "${_list[@]}"; do
        if [[ -f ${_file} ]]; then
            _msg_debug "Removeing ${_file}"
            rm -f "${_file}"
            elif [[ -d ${_file} ]]; then
            _msg_debug "Removeing ${_file}"
            rm -rf "${_file}"
        fi
    done
}

# Debug line
debug_line() {
    [[ "${debug}" = true ]] && echo
}

# 強制終了時にアンマウント
umount_trap() {
    local status=${?}
    umount_chroot
    _msg_error "It was killed by the user."
    _msg_error "The process may not have completed successfully."
    exit ${status}
}

# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local file
    for file in ${@}; do
        if [[ -f "${file}" ]]; then
            source "${file}"
            _msg_debug "The settings have been overwritten by the ${file}"
        fi
    done
}

# Display channel list
show_channel_list() {
    local i
    for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9 }'); do
        if [[ -n $(ls "${script_path}"/channels/${i}) ]] && [[ ! ${i} = "share" ]]; then
            if [[ ! $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                if [[ ! -d "${script_path}/channels/${i}.add" ]]; then
                    echo -n "${i} "
                fi
            else
                echo -n "${i} "
            fi
        fi
    done
    echo
    exit 0
}

# Check the value of a variable that can only be set to true or false.
check_bool() {
    local _value="$(eval echo '$'${1})"
    _msg_debug -n "Checking ${1}..."
    if [[ "${debug}" = true ]]; then
        echo -e " ${_value}"
    fi
    if [[ ! -v "${1}" ]]; then
        echo; _msg_error "The variable name ${1} is empty." "1"
        elif [[ ! "${_value}" = "true" ]] && [[ ! "${_value}" = "false" ]]; then
        echo; _msg_error "The variable name ${1} is not of bool type." "1"
    fi
}


# Preparation for build
prepare_build() {
    # Create a working directory.
    [[ ! -d "${work_dir}" ]] && mkdir -p "${work_dir}"

    # Check work dir
    if [[ -n $(ls -a "${work_dir}" 2> /dev/null | grep -xv ".." | grep -xv ".") ]] && [[ ! "${rebuild}" = true ]]; then
        umount_chroot
        _msg_info "Deleting the contents of ${work_dir}..."
        remove "${work_dir%/}/${arch}"
        remove "${work_dir%/}/lockfile"
        remove "${work_dir%/}/packages.list"
        remove "${work_dir%/}/logs"
        remove "${work_dir%/}/pacman/db"
        remove "${rebuildfile}"
        remove "${work_dir%/}/pacman-"*".conf"
    fi
    
    # 強制終了時に作業ディレクトリを削除する
    local trap_remove_work
    trap_remove_work() {
        local status=${?}
        echo
        remove "${work_dir}"
        exit ${status}
    }
    trap 'trap_remove_work' 1 2 3 15
    
    if [[ ${rebuild} = false ]]; then
        # If there is pacman.conf for each channel, use that for building
        if [[ -f "${script_path}/channels/${channel_name}/pacman-${arch}.conf" ]]; then
            build_pacman_conf="${script_path}/channels/${channel_name}/pacman-${arch}.conf"
        fi
        
        # If there is config for share channel. load that.
        load_config "${script_path}/channels/share/config.any"
        load_config "${script_path}/channels/share/config.${arch}"
        
        # If there is config for each channel. load that.
        load_config "${script_path}/channels/${channel_name}/config.any"
        load_config "${script_path}/channels/${channel_name}/config.${arch}"
        
        # Set username
        if [[ "${customized_username}" = false ]]; then
            username="${defaultusername}"
        fi
        
        # gitversion
        if [[ "${gitversion}" = true ]]; then
            cd ${script_path}
            iso_version=${iso_version}-$(git rev-parse --short HEAD)
            cd - > /dev/null 2>&1
        fi
        
        # Generate iso file name.
        local _channel_name
        if [[ $(echo "${channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
            _channel_name="$(echo ${channel_name} | sed 's/\.[^\.]*$//')-${locale_version}"
        else
            _channel_name="${channel_name}-${locale_version}"
        fi
        if [[ "${nochname}" = true ]]; then
            iso_filename="${iso_name}-${iso_version}-${arch}.iso"
        else
            iso_filename="${iso_name}-${_channel_name}-${iso_version}-${arch}.iso"
        fi
        _msg_debug "Iso filename is ${iso_filename}"
    
        # Save build options
        local write_rebuild_file
        write_rebuild_file() {
            local out_file="${rebuildfile}"
            echo -e "${@}" >> "${out_file}"
        }

        local save_var
        save_var() {
            local out_file="${rebuildfile}" i
            for i in ${@}; do
                echo -n "${i}=" >> "${out_file}"
                echo -n '"' >> "${out_file}"
                eval echo -n '$'{${i}} >> "${out_file}"
                echo '"' >> "${out_file}"
            done
        }

        # Save the value of the variable for use in rebuild.
        remove "${rebuildfile}"
        write_rebuild_file "#!/usr/bin/env bash"
        write_rebuild_file "# Build options are stored here."

        write_rebuild_file "\n# OS Info"
        save_var arch
        save_var os_name
        save_var iso_name
        save_var iso_label
        save_var iso_publisher
        save_var iso_application
        save_var iso_version
        save_var iso_filename
        save_var channel_name

        write_rebuild_file "\n# Environment Info"
        save_var install_dir
        save_var work_dir
        save_var out_dir
        save_var gpg_key

        write_rebuild_file "\n# Live User Info"
        save_var username
        save_var password
        save_var usershell

        write_rebuild_file "\n# Plymouth Info"
        save_var boot_splash
        save_var theme_name
        save_var theme_pkg

        write_rebuild_file "\n# Language Info"
        save_var locale_name
        save_var locale_gen_name
        save_var locale_version
        save_var locale_time
        save_var locale_fullname
        
        write_rebuild_file "\n# Kernel Info"
        save_var kernel
        save_var kernel_package
        save_var kernel_headers_packages
        save_var kernel_filename
        save_var kernel_mkinitcpio_profile

        write_rebuild_file "\n# Squashfs Info"
        save_var sfs_comp
        save_var sfs_comp_opt

        write_rebuild_file "\n# Debug Info"
        save_var noaur
        save_var gitversion
        save_var noloopmod

        write_rebuild_file "\n# Channel Info"
        save_var build_pacman_conf
        save_var defaultconfig
        save_var defaultusername
        save_var customized_username

        write_rebuild_file "\n# mkalteriso Info"
        if [[ "${shmkalteriso}" = false ]]; then
            mkalteriso="${script_path}/system/mkalteriso"
        else
            mkalteriso="${script_path}/system/mkalteriso.sh"
        fi

        save_var mkalteriso
        save_var shmkalteriso
        save_var mkalteriso_option
        save_var tarball
    else
        # Load rebuild file
        load_config "${rebuildfile}"
        _msg_debug "Iso filename is ${iso_filename}"
    fi

    # check bool
    check_bool boot_splash
    check_bool cleaning
    check_bool noconfirm
    check_bool nodepend
    check_bool shmkalteriso
    check_bool customized_username
    check_bool noloopmod
    check_bool nochname
    check_bool tarball
    check_bool noiso
    check_bool noaur

    # Check architecture for each channel
    if [[ -z $(cat "${script_path}/channels/${channel_name}/architecture" | grep -h -v ^'#' | grep -x "${arch}") ]]; then
        _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"
    fi

    # Check kernel for each channel
    if [[ -f "${script_path}/channels/${channel_name}/kernel_list-${arch}" ]] && [[ -z $(cat "${script_path}/channels/${channel_name}/kernel_list-${arch}" | grep -h -v ^'#' | grep -x "${kernel}" 2> /dev/null) ]]; then
        _msg_error "This kernel is currently not supported on this channel." "1"
    fi
    
    # Build mkalteriso
    if [[ "${shmkalteriso}" = false ]]; then
        mkalteriso="${script_path}/system/mkalteriso"
        cd "${script_path}"
        _msg_info "Building mkalteriso..."
        if [[ "${debug}" = true ]]; then
            make mkalteriso
            echo
        else
            make mkalteriso > /dev/null 2>&1
        fi
        cd - > /dev/null 2>&1
    else
        mkalteriso="${script_path}/system/mkalteriso.sh"
    fi

    # Show alteriso version
    if [[ -d "${script_path}/.git" ]]; then
        cd  "${script_path}"
        _msg_debug "The version of alteriso is $(git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')."
        cd - > /dev/null 2>&1
    fi

    # Unmount
    local mount
    for mount in $(mount | awk '{print $3}' | grep $(realpath ${work_dir})); do
        _msg_info "Unmounting ${mount}"
        umount "${mount}"
    done
    
    # Check packages
    if [[ "${nodepend}" = false ]] && [[ "${arch}" = $(uname -m) ]] ; then
        local check_pkg check_failed=false pkg
        local installed_pkg=($(pacman -Q | awk '{print $1}')) installed_ver=($(pacman -Q | awk '{print $2}'))

        check_pkg() {
            local i ver
            for i in $(seq 0 $(( ${#installed_pkg[@]} - 1 ))); do
                if [[ "${installed_pkg[${i}]}" = ${1} ]]; then
                    ver=$(pacman -Sp --print-format '%v' --config ${build_pacman_conf} ${1} 2> /dev/null)
                    if [[ "${installed_ver[${i}]}" = "${ver}" ]]; then
                        echo -n "installed"
                        return 0
                        elif [[ -z ${ver} ]]; then
                        echo "norepo"
                        return 0
                    else
                        echo -n "old"
                        return 0
                    fi
                fi
            done
            echo -n "not"
            return 0
        }
        if [[ ${debug} = false ]]; then
            _msg_info "Checking dependencies ..."
        else
            echo
        fi
        for pkg in ${dependence[@]}; do
            _msg_debug -n "Checking ${pkg} ..."
            case $(check_pkg ${pkg}) in
                "old")
                    [[ "${debug}" = true ]] && echo -ne " $(pacman -Q ${pkg} | awk '{print $2}')\n"
                    _msg_warn "${pkg} is not the latest package."
                    _msg_warn "Local: $(pacman -Q ${pkg} 2> /dev/null | awk '{print $2}') Latest: $(pacman -Sp --print-format '%v' --config ${build_pacman_conf} ${pkg} 2> /dev/null)"
                ;;
                "not")
                    [[ "${debug}" = true ]] && echo
                    _msg_error "${pkg} is not installed." ; check_failed=true
                ;;
                "norepo")
                    [[ "${debug}" = true ]] && echo
                    _msg_warn "${pkg} is not a repository package."
                ;;
                "installed") [[ ${debug} = true ]] && echo -ne " $(pacman -Q ${pkg} | awk '{print $2}')\n" ;;
            esac
        done
        
        if [[ "${check_failed}" = true ]]; then
            exit 1
        fi
    fi
    
    # Load loop kernel module
    if [[ "${noloopmod}" = false ]]; then
        if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
            _msg_error "The currently running kernel module could not be found."
            _msg_error "Probably the system kernel has been updated."
            _msg_error "Reboot your system to run the latest kernel." "1"
        fi
        if [[ -z $(lsmod | awk '{print $1}' | grep -x "loop") ]]; then
            sudo modprobe loop
        fi
    fi
}


# Show settings.
show_settings() {
    _msg_info "mkalteriso path is ${mkalteriso}"
    echo
    if [[ "${boot_splash}" = true ]]; then
        _msg_info "Boot splash is enabled."
        _msg_info "Theme is used ${theme_name}."
    fi
    _msg_info "Language is ${locale_fullname}."
    _msg_info "Use the ${kernel} kernel."
    _msg_info "Live username is ${username}."
    _msg_info "Live user password is ${password}."
    _msg_info "The compression method of squashfs is ${sfs_comp}."
    if [[ $(echo "${channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
        _msg_info "Use the $(echo ${channel_name} | sed 's/\.[^\.]*$//') channel."
    else
        _msg_info "Use the ${channel_name} channel."
    fi
    _msg_info "Build with architecture ${arch}."
    echo
    if [[ ${noconfirm} = false ]]; then
        echo "Press Enter to continue or Ctrl + C to cancel."
        read
    fi
    trap 1 2 3 15
    trap 'umount_trap' 1 2 3 15
}


# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    _msg_debug "Use ${build_pacman_conf}"

    # Prepare dir
    mkdir -p "${pacman_cache_dir%/}/"
    mkdir -p "${pacman_db_dir%/}/"
    mkdir -p "$(dirname "${pacman_log}")"

    sed -r "s|^#?\\s*CacheDir.+|CacheDir    = ${pacman_cache_dir}|g;
            s|^#?\\s*DBPath.+|DBPath      = ${pacman_db_dir}|g;
            s|^#?\\s*LogFile.+|LogFile     = ${pacman_log}|g;
            " ${build_pacman_conf} > "${work_dir}/pacman-${arch}.conf"
}

# Base installation, plus needed packages (airootfs)
make_basefs() {
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" init
    # ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "haveged intel-ucode amd-ucode memtest86+ mkinitcpio-nfs-utils nbd zsh efitools" install
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "bash haveged intel-ucode amd-ucode mkinitcpio-nfs-utils nbd" install

    # Install plymouth.
    if [[ "${boot_splash}" = true ]]; then
        if [[ -n "${theme_pkg}" ]]; then
            ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "plymouth ${theme_pkg}" install
        else
            ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "plymouth" install
        fi
    fi
    
    # Install kernel.
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${kernel_package} ${kernel_headers_packages}" install

    if [[ "${kernel_package}" = "linux" ]]; then
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "broadcom-wl" install
    else
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "broadcom-wl-dkms" install
    fi
}

# Additional packages (airootfs)
make_packages() {
    # データベースをairootfsにコピー
    cp -r "${pacman_db_dir}"/* "${work_dir}/${arch}/airootfs/var/lib/pacman"

    # インストールするパッケージのリストを読み込み、配列pkglistに代入します。
    set +e
    local _loadfilelist _pkg _file excludefile excludelist _pkglist
    
    #-- Detect package list to load --#
    # Add the files for each channel to the list of files to read.
    _loadfilelist=(
        $(ls "${script_path}"/channels/${channel_name}/packages.${arch}/*.${arch} 2> /dev/null)
        "${script_path}/channels/${channel_name}/packages.${arch}/lang/${locale_name}.${arch}"
        $(ls "${script_path}"/channels/share/packages.${arch}/*.${arch} 2> /dev/null)
        "${script_path}/channels/share/packages.${arch}/lang/${locale_name}.${arch}"
    )
    
    
    #-- Read package list --#
    # Read the file and remove comments starting with # and add it to the list of packages to install.
    for _file in ${_loadfilelist[@]}; do
        if [[ -f "${_file}" ]]; then
            _msg_debug "Loaded package file ${_file}."
            pkglist=( ${pkglist[@]} "$(grep -h -v ^'#' ${_file})" )
        fi
    done

    #-- Read exclude list --#
    # Exclude packages from the share exclusion list
    excludefile=(
        "${script_path}/channels/share/packages.${arch}/exclude"
        "${script_path}/channels/${channel_name}/packages.${arch}/exclude"
    )

    for _file in ${excludefile[@]}; do
        if [[ -f "${_file}" ]]; then
            excludelist=( ${excludelist[@]} $(grep -h -v ^'#' "${_file}") )
        fi
    done

    # 現在のpkglistをコピーする
    _pkglist=(${pkglist[@]})
    unset pkglist
    for _pkg in ${_pkglist[@]}; do
        # もし変数_pkgの値が配列excludelistに含まれていなかったらpkglistに追加する
        if [[ ! $(printf '%s\n' "${excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
            pkglist=(${pkglist[@]} "${_pkg}")
        fi
    done

    if [[ -n "${excludelist[*]}" ]]; then
        _msg_debug "The following packages have been removed from the installation list."
        _msg_debug "Excluded packages:" "${excludelist[@]}"
    fi

    # Sort the list of packages in abc order.
    pkglist=(
        "$(
            for _pkg in ${pkglist[@]}; do
                echo "${_pkg}"
            done \
            | sort
        )"
    )
    set -e
    
    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    local _log_packages_list="${work_dir}/logs/packages.list"
    echo -e "# The list of packages that is installed in live cd.\n#\n" > "${_log_packages_list}"
    for _pkg in ${pkglist[@]}; do
        echo ${_pkg} >> "${_log_packages_list}"
    done
    
    # Install packages on airootfs
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${pkglist[@]}" install
}


make_packages_aur() {
    # インストールするパッケージのリストを読み込み、配列pkglistに代入します。
    set +e

    local _loadfilelist _pkg _file excludefile excludelist _pkglist
    
    #-- Detect package list to load --#
    # Add the files for each channel to the list of files to read.
    _loadfilelist=(
        $(ls "${script_path}"/channels/${channel_name}/packages_aur.${arch}/*.${arch} 2> /dev/null)
        "${script_path}"/channels/${channel_name}/packages_aur.${arch}/lang/${locale_name}.${arch}
        $(ls "${script_path}"/channels/share/packages_aur.${arch}/*.${arch} 2> /dev/null)
        "${script_path}"/channels/share/packages_aur.${arch}/lang/${locale_name}.${arch}
    )

    if [[ ! -d "${script_path}/channels/${channel_name}/packages_aur.${arch}/" ]] && [[ ! -d "${script_path}/channels/share/packages_aur.${arch}/" ]]; then
        return
    fi

    #-- Read package list --#
    # Read the file and remove comments starting with # and add it to the list of packages to install.
    for _file in ${_loadfilelist[@]}; do
        if [[ -f "${_file}" ]]; then
            _msg_debug "Loaded aur package file ${_file}."
            pkglist_aur=( ${pkglist_aur[@]} "$(grep -h -v ^'#' ${_file})" )
        fi
    done
    
    #-- Read exclude list --#
    # Exclude packages from the share exclusion list
    excludefile=(
        "${script_path}/channels/share/packages_aur.${arch}/exclude"
        "${script_path}/channels/${channel_name}/packages_aur.${arch}/exclude"
    )

    for _file in ${excludefile[@]}; do
        [[ -f "${_file}" ]] && excludelist=( ${excludelist[@]} $(grep -h -v ^'#' "${_file}") )
    done
    # 現在のpkglistをコピーする
    _pkglist=(${pkglist[@]})
    unset pkglist
    for _pkg in ${_pkglist[@]}; do
        # もし変数_pkgの値が配列excludelistに含まれていなかったらpkglistに追加する
        if [[ ! $(printf '%s\n' "${excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
            pkglist=(${pkglist[@]} "${_pkg}")
        fi
    done

    if [[ -n "${excludelist[*]}" ]]; then
        _msg_debug "The following packages have been removed from the aur list."
        _msg_debug "Excluded packages:" "${excludelist[@]}"
    fi

    # Sort the list of packages in abc order.
    pkglist_aur=(
        "$(
            for _pkg in ${pkglist_aur[@]}; do
                echo "${_pkg}"
            done \
            | sort
        )"
    )
    set -e
    
    # _msg_debug "${pkglist[@]}"
    
    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    local _log_packages_list="${work_dir}/logs/aur_packages.list"
    echo -e "# The list of packages from AUR that is installed in live cd.\n#\n" > "${_log_packages_list}"
    for _pkg in ${pkglist_aur[@]}; do
        echo ${_pkg} >> "${_log_packages_list}"
    done
    
    # Build aur packages on airootfs
    local _aur_pkg
    local _copy_aur_scripts
    _copy_aur_scripts() {
        cp -r "${script_path}/system/aur_scripts/${1}.sh" "${work_dir}/${arch}/airootfs/root/${1}.sh"
        chmod 755 "${work_dir}/${arch}/airootfs/root/${1}.sh"
    }

    _copy_aur_scripts aur_install
    _copy_aur_scripts aur_prepare
    _copy_aur_scripts aur_remove
    _copy_aur_scripts pacls_gen_new
    _copy_aur_scripts pacls_gen_old


    local _aur_packages_ls_str=""
    for _pkg in ${pkglist_aur[@]}; do
        _aur_packages_ls_str="${_aur_packages_ls_str} ${_pkg}"
    done

    # Create user to build AUR
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -D "${install_dir}" -r "/root/aur_prepare.sh ${_aur_packages_ls_str}" run 
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -D "${install_dir}" -r "/root/pacls_gen_old.sh" run
    # Install dependent packages.
    "${script_path}/system/aur_scripts/PKGBUILD_DEPENDS_INSTALL.sh" "${work_dir}/pacman-${arch}.conf" "${work_dir}/${arch}/airootfs" ${_aur_packages_ls_str}
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -D "${install_dir}" -r "/root/pacls_gen_new.sh" run
    # Build the package using makepkg.
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -D "${install_dir}" -r "/root/aur_install.sh ${_aur_packages_ls_str}" run
  
    # Install the built package file.
    for _pkg in ${pkglist_aur[@]}; do
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${work_dir}/${arch}/airootfs/aurbuild_temp/${_pkg}/*.pkg.tar.*" install_file
    done
    delete_pkg_list=(`comm -13 --nocheck-order "${work_dir}/${arch}/airootfs/paclist_old" "${work_dir}/${arch}/airootfs/paclist_new" |xargs`)
    for _dlpkg in ${delete_pkg_list[@]}; do
        unshare --fork --pid pacman -r "${work_dir}/${arch}/airootfs" -R --noconfirm ${_dlpkg}
    done
    rm -f "${work_dir}/${arch}/airootfs/paclist_old"
    rm -f "${work_dir}/${arch}/airootfs/paclist_new"
    # Delete the user created for the build.
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/aur_remove.sh" run
}

# Customize installation (airootfs)
make_customize_airootfs() {
    # Overwrite airootfs with customize_airootfs.
    local copy_airootfs
    
    copy_airootfs() {
        local _dir="${1%/}"
        if [[ -d "${_dir}" ]]; then
            cp -af "${_dir}"/* "${work_dir}/${arch}/airootfs"
        fi
    }

    copy_airootfs "${script_path}/channels/share/airootfs.any"
    copy_airootfs "${script_path}/channels/share/airootfs.${arch}"
    copy_airootfs "${script_path}/channels/${channel_name}/airootfs.any"
    copy_airootfs "${script_path}/channels/${channel_name}/airootfs.${arch}"
    
    # Replace /etc/mkinitcpio.conf if Plymouth is enabled.
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-plymouth.conf" "${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf"
    fi

    # customize_airootfs options
    # -b                        : Enable boot splash.
    # -d                        : Enable debug mode.
    # -g <locale_gen_name>      : Set locale-gen.
    # -i <inst_dir>             : Set install dir
    # -k <kernel config line>   : Set kernel name.
    # -o <os name>              : Set os name.
    # -p <password>             : Set password.
    # -s <shell>                : Set user shell.
    # -t                        : Set plymouth theme.
    # -u <username>             : Set live user name.
    # -x                        : Enable bash debug mode.
    # -r                        : Enable rebuild.
    # -z <locale_time>          : Set the time zone.
    # -l <locale_name>          : Set language.
    #
    # -j is obsolete in AlterISO3 and cannot be used.
    # -k changed in AlterISO3 from passing kernel name to passing kernel configuration.
    
    
    # Generate options of customize_airootfs.sh.
    local airootfs_script_options
    airootfs_script_options="-p '${password}' -k '${kernel} ${kernel_package} ${kernel_headers_packages} ${kernel_filename} ${kernel_mkinitcpio_profile}' -u '${username}' -o '${os_name}' -i '${install_dir}' -s '${usershell}' -a '${arch}' -g '${locale_gen_name}' -l '${locale_name}' -z '${locale_time}' -t ${theme_name}"
    [[ ${boot_splash} = true ]] && airootfs_script_options="${airootfs_script_options} -b"
    [[ ${debug} = true ]]       && airootfs_script_options="${airootfs_script_options} -d"
    [[ ${bash_debug} = true ]]  && airootfs_script_options="${airootfs_script_options} -x"
    [[ ${rebuild} = true ]]     && airootfs_script_options="${airootfs_script_options} -r"

    # X permission
    local chmod_755
    chmod_755() {
        _file="${1}"
        if [[ -f "$_file" ]]; then
            chmod 755 "${_file}"
    
        fi
    }
    
    chmod_755 "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh"
    chmod_755 "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh"
    chmod_755 "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh"
    chmod_755 "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh"
    
    # Execute customize_airootfs.sh.
    ${mkalteriso} ${mkalteriso_option} \
    -w "${work_dir}/${arch}" \
    -C "${work_dir}/pacman-${arch}.conf" \
    -D "${install_dir}" \
    -r "/root/customize_airootfs.sh ${airootfs_script_options}" \
    run

    if [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh" ]]; then
        ${mkalteriso} ${mkalteriso_option} \
        -w "${work_dir}/${arch}" \
        -C "${work_dir}/pacman-${arch}.conf" \
        -D "${install_dir}" \
        -r "/root/customize_airootfs_${channel_name}.sh ${airootfs_script_options}" \
        run
    elif [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh" ]]; then
        ${mkalteriso} ${mkalteriso_option} \
        -w "${work_dir}/${arch}" \
        -C "${work_dir}/pacman-${arch}.conf" \
        -D "${install_dir}" \
        -r "/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh ${airootfs_script_options}" \
        run
    fi
    
    # Delete customize_airootfs.sh.
    remove "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh"
    remove "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh"
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${work_dir}/${arch}/airootfs/etc/initcpio/hooks"
    mkdir -p "${work_dir}/${arch}/airootfs/etc/initcpio/install"
    for _hook in "archiso" "archiso_shutdown" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${work_dir}/${arch}/airootfs/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${work_dir}/${arch}/airootfs/etc/initcpio/install"
    done
    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" "${work_dir}/${arch}/airootfs/etc/initcpio/install/archiso_shutdown"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${work_dir}/${arch}/airootfs/etc/initcpio/install"
    cp "${script_path}/system/initcpio/archiso_shutdown" "${work_dir}/${arch}/airootfs/etc/initcpio"
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso-plymouth.conf" "${work_dir}/${arch}/airootfs/etc/mkinitcpio-archiso.conf"
    else
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso.conf" "${work_dir}/${arch}/airootfs/etc/mkinitcpio-archiso.conf"
    fi
    gnupg_fd=
    if [[ "${gpg_key}" ]]; then
        gpg --export "${gpg_key}" >"${work_dir}/gpgkey"
        exec 17<>$"{work_dir}/gpgkey"
    fi
    
    ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/${kernel_filename} -g /boot/archiso.img" run
    
    if [[ "${gpg_key}" ]]; then
        exec 17<&-
    fi
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p "${work_dir}/iso/${install_dir}/boot/${arch}"
    cp "${work_dir}/${arch}/airootfs/boot/archiso.img" "${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img"
    cp "${work_dir}/${arch}/airootfs/boot/${kernel_filename}" "${work_dir}/iso/${install_dir}/boot/${arch}/${kernel_filename}"
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    cp "${work_dir}/${arch}/airootfs/boot/intel-ucode.img" "${work_dir}/iso/${install_dir}/boot/intel_ucode.img"
    cp "${work_dir}/${arch}/airootfs/usr/share/licenses/intel-ucode/LICENSE" "${work_dir}/iso/${install_dir}/boot/intel_ucode.LICENSE"
    cp "${work_dir}/${arch}/airootfs/boot/amd-ucode.img" "${work_dir}/iso/${install_dir}/boot/amd_ucode.img"
    cp "${work_dir}/${arch}/airootfs/usr/share/licenses/amd-ucode/LICENSE.amd-ucode" "${work_dir}/iso/${install_dir}/boot/amd_ucode.LICENSE"
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    _uname_r="$(file -b ${work_dir}/${arch}/airootfs/boot/${kernel_filename} | awk 'f{print;f=0} /version/{f=1}' RS=' ')"
    mkdir -p "${work_dir}/iso/${install_dir}/boot/syslinux"
    
    # copy all syslinux config to work dir
    for _cfg in ${script_path}/syslinux/${arch}/*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%INSTALL_DIR%|${install_dir}|g" "${_cfg}" > "${work_dir}/iso/${install_dir}/boot/syslinux/${_cfg##*/}"
    done
    
    # Replace the SYSLINUX configuration file with or without boot splash.
    local _use_config_name _no_use_config_name _pxe_or_sys
    if [[ "${boot_splash}" = true ]]; then
        _use_config_name=splash
        _no_use_config_name=nosplash
    else
        _use_config_name=nosplash
        _no_use_config_name=splash
    fi
    for _pxe_or_sys in "sys" "pxe"; do
        remove "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}_${_no_use_config_name}.cfg"
        mv "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}_${_use_config_name}.cfg" "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}.cfg"
    done

    # Set syslinux wallpaper
    if [[ -f "${script_path}/channels/${channel_name}/splash.png" ]]; then
        cp "${script_path}/channels/${channel_name}/splash.png" "${work_dir}/iso/${install_dir}/boot/syslinux"
    else
        cp "${script_path}/syslinux/${arch}/splash.png" "${work_dir}/iso/${install_dir}/boot/syslinux"
    fi

    # copy files
    cp "${work_dir}"/${arch}/airootfs/usr/lib/syslinux/bios/*.c32 "${work_dir}/iso/${install_dir}/boot/syslinux"
    cp "${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/lpxelinux.0" "${work_dir}/iso/${install_dir}/boot/syslinux"
    cp "${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/memdisk" "${work_dir}/iso/${install_dir}/boot/syslinux"
    mkdir -p "${work_dir}/iso/${install_dir}/boot/syslinux/hdt"
    gzip -c -9 "${work_dir}/${arch}/airootfs/usr/share/hwdata/pci.ids" > "${work_dir}/iso/${install_dir}/boot/syslinux/hdt/pciids.gz"
    gzip -c -9 "${work_dir}/${arch}/airootfs/usr/lib/modules/${_uname_r}/modules.alias" > "${work_dir}/iso/${install_dir}/boot/syslinux/hdt/modalias.gz"
}

# Prepare /isolinux
make_isolinux() {
    mkdir -p "${work_dir}/iso/isolinux"
    
    sed "s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/system/isolinux.cfg" > "${work_dir}/iso/isolinux/isolinux.cfg"
    cp "${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isolinux.bin" "${work_dir}/iso/isolinux/"
    cp "${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin" "${work_dir}/iso/isolinux/"
    cp "${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/ldlinux.c32" "${work_dir}/iso/isolinux/"
}

# Prepare /EFI
make_efi() {
    mkdir -p "${work_dir}/iso/EFI/boot"
    cp "${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" "${work_dir}/iso/EFI/boot/bootx64.efi"

    mkdir -p "${work_dir}/iso/loader/entries"
    cp "${script_path}/efiboot/loader/loader.conf" "${work_dir}/iso/loader/"

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%KERNEL_FILENAME%|${kernel_filename}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/efiboot/loader/entries/archiso-x86_64-usb.conf" > "${work_dir}/iso/loader/entries/archiso-x86_64.conf"
    
    # edk2-shell based UEFI shell
    # shellx64.efi is picked up automatically when on /
    cp "/usr/share/edk2-shell/x64/Shell_Full.efi" "${work_dir}/iso/shellx64.efi"
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {
    mkdir -p "${work_dir}/iso/EFI/archiso"
    truncate -s 64M "${work_dir}/iso/EFI/archiso/efiboot.img"
    mkfs.fat -n ARCHISO_EFI "${work_dir}/iso/EFI/archiso/efiboot.img"
    
    mkdir -p "${work_dir}/efiboot"
    mount "${work_dir}/iso/EFI/archiso/efiboot.img" "${work_dir}/efiboot"
    
    mkdir -p "${work_dir}/efiboot/EFI/archiso"
    
    cp "${work_dir}/iso/${install_dir}/boot/${arch}/${kernel_filename}" "${work_dir}/efiboot/EFI/archiso/${kernel_filename}.efi"
    cp "${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img" "${work_dir}/efiboot/EFI/archiso/archiso.img"
    
    cp "${work_dir}/iso/${install_dir}/boot/intel_ucode.img" "${work_dir}/efiboot/EFI/archiso/intel_ucode.img"
    cp "${work_dir}/iso/${install_dir}/boot/amd_ucode.img" "${work_dir}/efiboot/EFI/archiso/amd_ucode.img"
    
    mkdir -p "${work_dir}/efiboot/EFI/boot"
    cp "${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" "${work_dir}/efiboot/EFI/boot/bootx64.efi"

    mkdir -p "${work_dir}/efiboot/loader/entries"
    cp "${script_path}/efiboot/loader/loader.conf" "${work_dir}/efiboot/loader/"


    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%KERNEL_FILENAME%|${kernel_filename}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/efiboot/loader/entries/archiso-x86_64-cd.conf" > "${work_dir}/efiboot/loader/entries/archiso-x86_64.conf"

    # shellx64.efi is picked up automatically when on /
    cp "${work_dir}/iso/shellx64.efi" "${work_dir}/efiboot/"

    umount -d "${work_dir}/efiboot"
}

# Compress tarball
make_tarball() {
    cp -a -l -f "${work_dir}/${arch}/airootfs" "${work_dir}"

    if [[ -f "${work_dir}/${arch}/airootfs/root/optimize_for_tarball.sh" ]]; then
        chmod 755 "${work_dir}/${arch}/airootfs/root/optimize_for_tarball.sh"
    fi

    arch-chroot "${work_dir}/airootfs" "/root/optimize_for_tarball.sh" -u ${username}
    ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r "mkinitcpio -p ${kernel_mkinitcpio_profile}" run

    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -P "${iso_publisher}" -A "${iso_application}" -o "${out_dir}" tarball "$(echo ${iso_filename} | sed 's/\.[^\.]*$//').tar.xz"

    remove "${work_dir}/airootfs"
}

# Build airootfs filesystem image
make_prepare() {
    cp -a -l -f "${work_dir}/${arch}/airootfs" "${work_dir}"
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" pkglist
    pacman -Q --sysroot "${work_dir}/airootfs" > "${work_dir}/packages-full.list"
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} -c "${sfs_comp}" -t "${sfs_comp_opt}" prepare
    remove "${work_dir}/airootfs"
    
    if [[ "${cleaning}" = true ]]; then
        remove "${work_dir}/${arch}/airootfs"
    fi
}

# Build ISO
make_iso() {
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -P "${iso_publisher}" -A "${iso_application}" -o "${out_dir}" iso "${iso_filename}"
    _msg_info "The password for the live user and root is ${password}."
}

# Parse files
parse_files() {
    #-- ロケールを解析、設定 --#
    local _get_locale_line_number _locale_config_file _locale_name_list _locale_line_number _locale_config_line

    # 選択されたロケールの設定が描かれた行番号を取得
    _locale_config_file="${script_path}/system/locale-${arch}"
    _locale_name_list=($(cat "${_locale_config_file}" | grep -h -v ^'#' | awk '{print $1}'))
    _get_locale_line_number() {
        local _lang count=0
        for _lang in ${_locale_name_list[@]}; do
            count=$(( count + 1 ))
            if [[ "${_lang}" == "${locale_name}" ]]; then
                echo "${count}"
                return 0
            fi
        done
        echo -n "failed"
        return 0
    }
    _locale_line_number="$(_get_locale_line_number)"

    # 不正なロケール名なら終了する
    [[ "${_locale_line_number}" == "failed" ]] && _msg_error "${locale_name} is not a valid language." "1"

    # ロケール設定ファイルから該当の行を抽出
    _locale_config_line="$(cat "${_locale_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_locale_line_number}" | tail -n 1)"

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
    locale_name=$(echo ${_locale_config_line} | awk '{print $1}')
    locale_gen_name=$(echo ${_locale_config_line} | awk '{print $2}')
    locale_version=$(echo ${_locale_config_line} | awk '{print $3}')
    locale_time=$(echo ${_locale_config_line} | awk '{print $4}')
    locale_fullname=$(echo ${_locale_config_line} | awk '{print $5}')


    #-- カーネルを解析、設定 --#
    local _kernel_config_file _kernel_name_list _kernel_line _get_kernel_line _kernel_config_line

    # 選択されたカーネルの設定が描かれた行番号を取得
    _kernel_config_file="${script_path}/system/kernel-${arch}"
    _kernel_name_list=($(cat "${_kernel_config_file}" | grep -h -v ^'#' | awk '{print $1}'))
    _get_kernel_line() {
        local _kernel
        local count
        count=0
        for _kernel in ${_kernel_name_list[@]}; do
            count=$(( count + 1 ))
            if [[ "${_kernel}" == "${kernel}" ]]; then
                echo "${count}"
                return 0
            fi
        done
        echo -n "failed"
        return 0
    }
    _kernel_line="$(_get_kernel_line)"

    # 不正なカーネル名なら終了する
    [[ "${_kernel_line}" == "failed" ]] && _msg_error "Invalid kernel ${kernel}" "1"

    # カーネル設定ファイルから該当の行を抽出
    _kernel_config_line="$(cat "${_kernel_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_kernel_line}" | tail -n 1)"

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
    kernel=$(echo ${_kernel_config_line} | awk '{print $1}')
    kernel_package=$(echo ${_kernel_config_line} | awk '{print $2}')
    kernel_headers_packages=$(echo ${_kernel_config_line} | awk '{print $3}')
    kernel_filename=$(echo ${_kernel_config_line} | awk '{print $4}')
    kernel_mkinitcpio_profile=$(echo ${_kernel_config_line} | awk '{print $5}')
}


# Parse options
options="${@}"
_opt_short="a:bc:dg:hjk:lo:p:t:u:w:x"
_opt_long="arch:,boot-splash,comp-type:,debug,help,lang,japanese,kernel:,cleaning,out:,password:,comp-opts:,user:,work:,bash-debug,nocolor,noconfirm,nodepend,gitversion,shmkalteriso,msgdebug,noloopmod,tarball,noiso,noaur,nochkver,channellist"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- "${@}")
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while :; do
    case ${1} in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --boot-splash)
            boot_splash=true
            shift 1
            ;;
        -c | --comp-type)
            case "${2}" in
                "gzip" | "lzma" | "lzo" | "lz4" | "xz" | "zstd") sfs_comp="${2}" ;;
                *) _msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        -d | --debug)
            debug=true
            shift 1
            ;;
        -g | --lang)
            locale_name="${2}"
            shift 2
            ;;
        -h | --help)
            _usage
            exit 0
            ;;
        -j | --japanese)
            _msg_error "This option is obsolete in AlterISO 3."
            _msg_error "To use Japanese, use \"-g ja\"." '1'
            ;;
        -k | --kernel)
            kernel="${2}"
            shift 2
            ;;
        -l | --cleaning)
            cleaning=true
            shift 1
            ;;
        -o | --out)
            out_dir="${2}"
            shift 2
            ;;
        -p | --password)
            password="${2}"
            shift 2
            ;;
        -t | --comp-opts)
            sfs_comp_opt="${2}"
            shift 2
            ;;
        -u | --user)
            customized_username=true
            username="$(echo -n "${2}" | sed 's/ //g' |tr '[A-Z]' '[a-z]')"
            shift 2
            ;;
        -w | --work)
            work_dir="${2}"
            shift 2
            ;;
        -x | --bash-debug)
            debug=true
            bash_debug=true
            shift 1
            ;;
        --noconfirm)
            noconfirm=true
            shift 1
            ;;
        --nodepend)
            nodepend=true
            shift 1
            ;;
        --nocolor)
            nocolor=true
            shift 1
            ;;
        --gitversion)
            if [[ -d "${script_path}/.git" ]]; then
                gitversion=true
            else
                _msg_error "There is no git directory. You need to use git clone to use this feature." "1"
            fi
            shift 1
            ;;
        --shmkalteriso)
            shmkalteriso=true
            shift 1
         ;;
        --msgdebug)
            msgdebug=true;
            shift 1
            ;;
        --noloopmod)
            noloopmod=true
            shift 1
            ;;
        --tarball)
            tarball=true
            shift 1
            ;;
        --noiso)
            noiso=true
            shift 1
            ;;
        --noaur)
            noaur=true
            shift 1
            ;;
        --nochkver)
            nochkver=true
            shift 1
            ;;
        --channellist)
            show_channel_list
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            _msg_error "Invalid argument '${1}'"
            _usage 1
            ;;
    esac
done


# Check root.
if [[ ${EUID} -ne 0 ]]; then
    _msg_warn "This script must be run as root." >&2
    # echo "Use -h to display script details." >&2
    # _usage 1
    _msg_warn "Re-run 'sudo ${0} ${options}'"
    sudo ${0} ${options}
    exit 1
fi

# Show config message
[[ -f "${defaultconfig}" ]] && _msg_debug "The settings have been overwritten by the ${defaultconfig}"

# Debug mode
mkalteriso_option="-a ${arch} -v"
if [[ "${bash_debug}" = true ]]; then
    set -x -v
    mkalteriso_option="${mkalteriso_option} -x"
fi

# Pacman configuration file used only when building
build_pacman_conf="${script_path}/system/pacman-${arch}.conf"

# Set rebuild config file
rebuildfile="${work_dir}/alteriso_config"

# Parse channels
set +eu
[[ -n "${1}" ]] && channel_name="${1}"

# check_channel <channel name>
check_channel() {
    local channel_list i
    channel_list=()
    for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9 }'); do
        if [[ -n $(ls "${script_path}"/channels/${i}) ]] && [[ ! ${i} = "share" ]]; then
            if [[ $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                channel_list="${channel_list[@]} ${i}"
            elif [[ ! -d "${script_path}/channels/${i}.add" ]]; then
                channel_list="${channel_list[@]} ${i}"
            fi
        fi
    done
    for i in ${channel_list[@]}; do
        if [[ $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
            if [[ $(echo ${i} | sed 's/\.[^\.]*$//') = ${1} ]] ; then
                echo -n "true"
                return 0
            fi
        elif [[ "${i}" == "${1}" ]] || [[ "${channel_name}" = "rebuild" ]] || [[ "${channel_name}" = "clean" ]]; then
            echo -n "true"
            return 0
        fi
    done
    
    echo -n "false"
    return 1
}

# Check for a valid channel name
[[ $(check_channel "${channel_name}") = false ]] && _msg_error "Invalid channel ${channel_name}" "1"

# Set for special channels
if [[ -d "${script_path}"/channels/${channel_name}.add ]]; then
    channel_name="${channel_name}.add"
elif [[ "${channel_name}" = "rebuild" ]]; then
    if [[ -f "${rebuildfile}" ]]; then
        rebuild=true
    else
        _msg_error "The previous build information is not in the working directory." "1"
    fi
elif [[ "${channel_name}" = "clean" ]]; then
    umount_chroot
    remove "${script_path}/menuconfig/build"
	remove "${script_path}/system/cpp-src/mkalteriso/build"
	remove "${script_path}/menuconfig-script/kernel_choice"
    remove "${work_dir}/${arch}"
    remove "${work_dir}/logs"
    remove "${work_dir}/lockfile"
    remove "${work_dir}/pacman-"*".conf"
    remove "${work_dir%/}/pacman/db"
    remove "${rebuildfile}"
    exit 0
fi

# Check channel version
if [[ ! "${channel_name}" == "rebuild" ]]; then
    _msg_debug "channel path is ${script_path}/channels/${channel_name}"
    if [[ ! "$(cat "${script_path}/channels/${channel_name}/alteriso" 2> /dev/null)" = "alteriso=3" ]] && [[ "${nochkver}" = false ]]; then
        _msg_error "This channel does not support AlterISO 3." "1"
    fi
fi

debug_line
check_bool rebuild
check_bool debug
check_bool bash_debug
check_bool nocolor
check_bool msgdebug
debug_line

parse_files

set -eu

prepare_build
show_settings
run_once make_pacman_conf
run_once make_basefs
run_once make_packages
[[ "${noaur}" = false ]] && run_once make_packages_aur
run_once make_customize_airootfs
run_once make_setup_mkinitcpio
run_once make_boot
run_once make_boot_extra
run_once make_syslinux
run_once make_isolinux
run_once make_efi
run_once make_efiboot
[[ "${tarball}" = true ]] && run_once make_tarball
[[ "${noiso}" = false ]] && run_once make_prepare
[[ "${noiso}" = false ]] && run_once make_iso
[[ "${cleaning}" = true ]] && remove "${work_dir}"

exit 0

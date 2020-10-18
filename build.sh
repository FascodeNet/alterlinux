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
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && pwd )"
defaultconfig="${script_path}/default.conf"
rebuild=false
customized_username=false
customized_password=false
DEFAULT_ARGUMENT=""
alteriso_version="3.0"

# Load config file
if [[ -f "${defaultconfig}" ]]; then
    source "${defaultconfig}"
else
    "${script_path}/tools/msg.sh" -a 'build.sh' error "${defaultconfig} was not found."
    exit 1
fi

# Load custom.conf
if [[ -f "${script_path}/custom.conf" ]]; then
    source "${script_path}/custom.conf"
fi

umask 0022

# Show an INFO message
# $1: message string
msg_info() {
    local _msg_opts="-a build.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    [[ "${msgdebug}" = true ]] && _msg_opts="${_msg_opts} -x"
    [[ "${nocolor}"  = true ]] && _msg_opts="${_msg_opts} -n"
    "${script_path}/tools/msg.sh" ${_msg_opts} info "${1}"
}

# Show an Warning message
# $1: message string
msg_warn() {
    local _msg_opts="-a build.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    [[ "${msgdebug}" = true ]] && _msg_opts="${_msg_opts} -x"
    [[ "${nocolor}"  = true ]] && _msg_opts="${_msg_opts} -n"
    "${script_path}/tools/msg.sh" ${_msg_opts} warn "${1}"
}

# Show an debug message
# $1: message string
msg_debug() {
    if [[ "${debug}" = true ]]; then
        local _msg_opts="-a build.sh"
        if [[ "${1}" = "-n" ]]; then
            _msg_opts="${_msg_opts} -o -n"
            shift 1
        fi
        [[ "${msgdebug}" = true ]] && _msg_opts="${_msg_opts} -x"
        [[ "${nocolor}"  = true ]] && _msg_opts="${_msg_opts} -n"
        "${script_path}/tools/msg.sh" ${_msg_opts} debug "${1}"
    fi
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
msg_error() {
    local _msg_opts="-a build.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    [[ "${msgdebug}" = true ]] && _msg_opts="${_msg_opts} -x"
    [[ "${nocolor}"  = true ]] && _msg_opts="${_msg_opts} -n"
    "${script_path}/tools/msg.sh" ${_msg_opts} error "${1}"
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}


# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}


_usage () {
    echo "usage ${0} [options] [channel]"
    echo
    echo "A channel is a profile of AlterISO settings."
    echo
    echo " General options:"
    echo "    -b | --boot-splash           Enable boot splash"
    echo "    -e | --cleanup | --cleaning  Enable post-build cleaning"
    echo "         --tarball               Build rootfs in tar.xz format"
    echo "    -h | --help                  This help message and exit"
    echo
    echo "    -a | --arch <arch>           Set iso architecture"
    echo "                                  Default: ${arch}"
    echo "    -c | --comp-type <comp_type> Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)"
    echo "                                  Default: ${sfs_comp}"
    echo "    -g | --gpgkey <key>          Set gpg key"
    echo "                                  Default: ${gpg_key}"
    echo "    -l | --lang <lang>           Specifies the default language for the live environment"
    echo "                                  Default: ${locale_name}"
    echo "    -k | --kernel <kernel>       Set special kernel type.See below for available kernels"
    echo "                                  Default: ${kernel}"
    echo "    -o | --out <out_dir>         Set the output directory"
    echo "                                  Default: ${out_dir}"
    echo "    -p | --password <password>   Set a live user password"
    echo "                                  Default: ${password}"
    echo "    -t | --comp-opts <options>   Set compressor-specific options."
    echo "                                  Default: empty"
    echo "    -u | --user <username>       Set user name"
    echo "                                  Default: ${username}"
    echo "    -w | --work <work_dir>       Set the working directory"
    echo "                                  Default: ${work_dir}"
    echo

    local blank="33" _arch _lang _list _locale_name_list kernel _dirname _channel _b

    echo " Language for each architecture:"
    for _list in ${script_path}/system/locale-* ; do
        _arch="${_list#${script_path}/system/locale-}"
        echo -n "    ${_arch}"
        for i in $( seq 1 $(( ${blank} - 4 - ${#_arch} )) ); do
            echo -ne " "
        done
        _locale_name_list=$(cat ${_list} | grep -h -v ^'#' | getclm 1)
        for _lang in ${_locale_name_list[@]};do
            echo -n "${_lang} "
        done
        echo
    done

    echo
    echo " Kernel for each architecture:"
    for _list in ${script_path}/system/kernel-* ; do
        _arch="${_list#${script_path}/system/kernel-}"
        echo -n "    ${_arch} "
        for i in $( seq 1 $(( ${blank} - 5 - ${#_arch} )) ); do echo -ne " "; done
        for kernel in $(grep -h -v ^'#' ${_list} | getclm 1); do echo -n "${kernel} "; done
        echo
    done

    echo
    echo " Channel:"
    for _dirname in $(bash "${script_path}/tools/channel.sh" -d -b -n show); do
        if [[ $(echo "${_dirname}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
            _channel="$(echo ${_dirname} | sed 's/\.[^\.]*$//')"
        else
            _channel="${_dirname}"
        fi
        echo -ne "    ${_channel}"
        for _b in $( seq 1 $(( ${blank} - 4 - ${#_channel} )) ); do echo -ne " "; done
        if [[ ! "$(cat "${script_path}/channels/${_dirname}/alteriso" 2> /dev/null)" = "alteriso=${alteriso_version}" ]] && [[ "${nochkver}" = false ]]; then
            "${script_path}/tools/msg.sh" --noadjust -l 'ERROR:' --noappname error "Not compatible with AlterISO3"
        elif [[ -f "${script_path}/channels/${_dirname}/description.txt" ]]; then
            echo -ne "$(cat "${script_path}/channels/${_dirname}/description.txt")\n"
        else
            "${script_path}/tools/msg.sh" --noadjust -l 'WARN :' --noappname warn "This channel does not have a description.txt"
        fi
    done
    echo -ne "    rebuild"
    for i in $( seq 1 $(( ${blank} - 11 )) ); do echo -ne " "; done
    echo -ne "Build from the point where it left off using the previous build settings.\n"

    echo
    echo " Debug options: Please use at your own risk."
    echo "    -d | --debug                 Enable debug messages"
    echo "    -x | --bash-debug            Enable bash debug mode(set -xv)"
    echo "         --channellist           Output the channel list and exit"
    echo "         --gitversion            Add Git commit hash to image file version"
    echo "         --msgdebug              Enables output debugging"
    echo "         --noaur                 No build and install AUR packages"
    echo "         --nocolor               No output colored output"
    echo "         --noconfirm             No check the settings before building"
    echo "         --nochkver              No check the version of the channel"
    echo "         --noefi                 No efi boot"
    echo "         --noloopmod             No check and load kernel module automatically"
    echo "         --nodepend              No check package dependencies before building"
    echo "         --noiso                 No build iso image (Use with --tarball)"
    echo "         --shmkalteriso          Use the shell script version of mkalteriso"
    if [[ -n "${1:-}" ]]; then exit "${1}"; fi
}


# Unmount chroot dir
umount_chroot () {
    local _mount
    for _mount in $(mount | getclm 3 | grep $(realpath ${work_dir}) | tac); do
        msg_info "Unmounting ${_mount}"
        umount -lf "${_mount}" 2> /dev/null
    done
}

# Helper function to run make_*() only one time.
run_once() {
    if [[ ! -e "${work_dir}/build.${1}_${arch}" ]]; then
        msg_debug "Running $1 ..."
        "$1"
        touch "${work_dir}/build.${1}_${arch}"
        umount_chroot
    else
        msg_debug "Skipped because ${1} has already been executed."
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
            msg_debug "Removing ${_file}"
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            msg_debug "Removing ${_file}"
            rm -rf "${_file}"
        fi
    done
}

# 強制終了時にアンマウント
umount_trap() {
    local _status=${?}
    umount_chroot
    msg_error "It was killed by the user.\nThe process may not have completed successfully."
    exit ${_status}
}

# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local _file
    for _file in ${@}; do
        if [[ -f "${_file}" ]]; then
            source "${_file}"
            msg_debug "The settings have been overwritten by the ${_file}"
        fi
    done
}

# Display channel list
show_channel_list() {
    if [[ "${nochkver}" = true ]]; then
        bash "${script_path}/tools/channel.sh" -v "${alteriso_version}" -n show
    else
        bash "${script_path}/tools/channel.sh" -v "${alteriso_version}" show
    fi
}

# Check the value of a variable that can only be set to true or false.
check_bool() {
    local _value="$(eval echo '$'${1})"
    msg_debug -n "Checking ${1}..."
    if [[ "${debug}" = true ]]; then
        echo -e " ${_value}"
    fi
    if [[ ! -v "${1}" ]]; then
        echo; msg_error "The variable name ${1} is empty." "1"
    elif [[ ! "${_value}" = "true" ]] && [[ ! "${_value}" = "false" ]]; then
        echo; msg_error "The variable name ${1} is not of bool type." "1"
    fi
}


# Check the build environment and create a directory.
prepare_env() {
    # Check packages
    if [[ "${nodepend}" = false ]]; then
        local _installed_pkg=($(pacman -Q | getclm 1)) _installed_ver=($(pacman -Q | getclm 2)) _check_pkg _check_failed=false _pkg
        msg_info "Checking dependencies ..."

        # _checl_pkg [package]
        _check_pkg() {
            local __pkg __ver
            msg_debug -n "Checking ${_pkg} ..."
            for __pkg in $(seq 0 $(( ${#_installed_pkg[@]} - 1 ))); do
                # パッケージがインストールされているかどうか
                if [[ "${_installed_pkg[${__pkg}]}" = ${1} ]]; then
                    __ver="$(pacman -Sp --print-format '%v' ${1} 2> /dev/null; :)"
                    if [[ "${_installed_ver[${__pkg}]}" = "${__ver}" ]]; then
                        # パッケージが最新の場合
                        [[ ${debug} = true ]] && echo -ne " $(pacman -Q ${1} | getclm 2)\n"
                        return 0
                    elif [[ -z ${__ver} ]]; then
                        # リモートのバージョンの取得に失敗した場合
                        [[ "${debug}" = true ]] && echo
                        msg_warn "${1} is not a repository package."
                        return 0
                    else
                        # リモートとローカルのバージョンが一致しない場合
                        [[ "${debug}" = true ]] && echo -ne " $(pacman -Q ${1} | getclm 2)\n"
                        msg_warn "${1} is not the latest package.\nLocal: $(pacman -Q ${1} 2> /dev/null | getclm 2) Latest: ${__ver}"
                        return 0
                    fi
                fi
            done
            [[ "${debug}" = true ]] && echo
            msg_error "${_pkg} is not installed." ; _check_failed=true
            return 0
        }

        for _pkg in ${dependence[@]}; do _check_pkg "${_pkg}"; done

        if [[ "${_check_failed}" = true ]]; then
            exit 1
        fi
    fi

    # Build mkalteriso
    if [[ "${shmkalteriso}" = false ]]; then
        mkalteriso="${script_path}/system/mkalteriso"
        cd "${script_path}"
        msg_info "Building mkalteriso..."
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

    # Load loop kernel module
    if [[ "${noloopmod}" = false ]]; then
        if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
            msg_error "The currently running kernel module could not be found.\nProbably the system kernel has been updated.\nReboot your system to run the latest kernel." "1"
        fi
        if [[ -z "$(lsmod | getclm 1 | grep -x "loop")" ]]; then modprobe loop; fi
    fi

    # Create a working directory.
    [[ ! -d "${work_dir}" ]] && mkdir -p "${work_dir}"

    # Check work dir
    if [[ -n $(ls -a "${work_dir}" 2> /dev/null | grep -xv ".." | grep -xv ".") ]] && [[ ! "${rebuild}" = true ]]; then
        umount_chroot
        msg_info "Deleting the contents of ${work_dir}..."
        remove "${work_dir%/}"/*
    fi

    # 強制終了時に作業ディレクトリを削除する
    local _trap_remove_work
    _trap_remove_work() {
        local status=${?}
        echo
        "${script_path}/tools/clean.sh" -o -w $(realpath "${work_dir}") $([[ "${debug}" = true ]] && echo -n "-d")
        exit ${status}
    }
    trap '_trap_remove_work' 1 2 3 15
}


# Show settings.
show_settings() {
    msg_debug "mkalteriso path is ${mkalteriso}"
    if [[ "${boot_splash}" = true ]]; then
        msg_info "Boot splash is enabled."
        msg_info "Theme is used ${theme_name}."
    fi
    msg_info "Language is ${locale_fullname}."
    msg_info "Use the ${kernel} kernel."
    msg_info "Live username is ${username}."
    msg_info "Live user password is ${password}."
    msg_info "The compression method of squashfs is ${sfs_comp}."
    if [[ $(echo "${channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
        msg_info "Use the $(echo ${channel_name} | sed 's/\.[^\.]*$//') channel."
    else
        msg_info "Use the ${channel_name} channel."
    fi
    msg_info "Build with architecture ${arch}."
    if [[ ${noconfirm} = false ]]; then
        echo
        echo "Press Enter to continue or Ctrl + C to cancel."
        read
    fi
    trap 1 2 3 15
    trap 'umount_trap' 1 2 3 15
}

# Save vars
prepare_rebuild() {
        # Save build options
        local _write_rebuild_file
        _write_rebuild_file() {
            local out_file="${rebuildfile}"
            echo -e "${@}" >> "${out_file}"
        }

        local _save_var
        _save_var() {
            local out_file="${rebuildfile}" i
            for i in ${@}; do echo "${i}=\"$(eval echo -n '$'${i})\"" >> "${out_file}"; done
        }

        # Save the value of the variable for use in rebuild.
        remove "${rebuildfile}"
        _write_rebuild_file "#!/usr/bin/env bash"
        _write_rebuild_file "# Build options are stored here."

        _write_rebuild_file "\n# OS Info"
        _save_var arch
        _save_var os_name
        _save_var iso_name
        _save_var iso_label
        _save_var iso_publisher
        _save_var iso_application
        _save_var iso_version
        _save_var iso_filename
        _save_var channel_name

        _write_rebuild_file "\n# Environment Info"
        _save_var channel_dir
        _save_var airootfs_dir
        _save_var isofs_dir
        _save_var install_dir
        _save_var work_dir
        _save_var out_dir
        _save_var gpg_key

        _write_rebuild_file "\n# Live User Info"
        _save_var username
        _save_var password
        _save_var usershell

        _write_rebuild_file "\n# Plymouth Info"
        _save_var boot_splash
        _save_var theme_name

        _write_rebuild_file "\n# Language Info"
        _save_var locale_name
        _save_var locale_gen_name
        _save_var locale_version
        _save_var locale_time
        _save_var locale_fullname

        _write_rebuild_file "\n# Kernel Info"
        _save_var kernel
        _save_var kernel_filename
        _save_var kernel_mkinitcpio_profile

        _write_rebuild_file "\n# Squashfs Info"
        _save_var sfs_comp
        _save_var sfs_comp_opt

        _write_rebuild_file "\n# Debug Info"
        _save_var noaur
        _save_var gitversion
        _save_var noloopmod

        _write_rebuild_file "\n# Channel Info"
        _save_var build_pacman_conf
        _save_var defaultconfig
        _save_var defaultusername
        _save_var customized_username
        _save_var customized_password

        _write_rebuild_file "\n# mkalteriso Info"
        if [[ "${shmkalteriso}" = false ]]; then
            mkalteriso="${script_path}/system/mkalteriso"
        else
            mkalteriso="${script_path}/system/mkalteriso.sh"
        fi

        _save_var mkalteriso
        _save_var shmkalteriso
        _save_var mkalteriso_option
        _save_var tarball

        _write_rebuild_file "\n# depend package"
        _write_rebuild_file "dependence=(${dependence[*]})"
}


# Preparation for build
prepare_build() {
    # Show alteriso version
    if [[ -d "${script_path}/.git" ]]; then
        cd  "${script_path}"
        msg_debug "The version of alteriso is $(git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')."
        cd - > /dev/null 2>&1
    fi

    if [[ "${rebuild}" = false ]]; then
        # Pacman configuration file used only when building
        # If there is pacman.conf for each channel, use that for building
        if [[ -f "${channel_dir}/pacman-${arch}.conf" ]]; then
            build_pacman_conf="${channel_dir}/pacman-${arch}.conf"
        else
            build_pacman_conf="${script_path}/system/pacman-${arch}.conf"
        fi

        # If there is config for share channel. load that.
        load_config "${script_path}/channels/share/config.any"
        load_config "${script_path}/channels/share/config.${arch}"

        # If there is config for each channel. load that.
        load_config "${channel_dir}/config.any"
        load_config "${channel_dir}/config.${arch}"

        # Set username
        if [[ "${customized_username}" = false ]]; then
            username="${defaultusername}"
        fi

       # Set password
        if [[ "${customized_password}" = false ]]; then
            password="${defaultpassword}"
        fi

        # gitversion
        if [[ "${gitversion}" = true ]]; then
            cd ${script_path}
            iso_version=${iso_version}-$(git rev-parse --short HEAD)
            cd - > /dev/null 2>&1
        fi

        # Set dirs
        airootfs_dir="${work_dir}/${arch}/airootfs"
        isofs_dir="${work_dir}/iso"

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
        msg_debug "Iso filename is ${iso_filename}"

        # Debug mode
        mkalteriso_option="-a ${arch} -v"
        if [[ "${bash_debug}" = true ]]; then
            set -x -v
            mkalteriso_option="${mkalteriso_option} -x"
        fi

        prepare_rebuild
    else
        # Load rebuild file
        load_config "${rebuildfile}"
        msg_debug "Iso filename is ${iso_filename}"
    fi

    # check bool
    check_bool boot_splash
    check_bool cleaning
    check_bool noconfirm
    check_bool nodepend
    check_bool shmkalteriso
    check_bool customized_username
    check_bool customized_password
    check_bool noloopmod
    check_bool nochname
    check_bool tarball
    check_bool noiso
    check_bool noaur
    check_bool customized_syslinux
    check_bool norescue_entry
    check_bool rebuild
    check_bool debug
    check_bool bash_debug
    check_bool nocolor
    check_bool msgdebug
    check_bool noefi

    # Check architecture for each channel
    if [[ -z $(cat "${channel_dir}/architecture" | grep -h -v ^'#' | grep -x "${arch}") ]]; then
        msg_error "${channel_name} channel does not support current architecture (${arch})." "1"
    fi


    # Check kernel for each channel
    if [[ -f "${channel_dir}/kernel_list-${arch}" ]] && [[ -z $(cat "${channel_dir}/kernel_list-${arch}" | grep -h -v ^'#' | grep -x "${kernel}" 2> /dev/null) ]]; then
        msg_error "This kernel is currently not supported on this channel." "1"
    fi

    # Unmount
    umount_chroot
}


# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    msg_debug "Use ${build_pacman_conf}"
    local _cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${_cache_dirs[@]})|g" ${build_pacman_conf} > "${work_dir}/pacman-${arch}.conf"
}

# Base installation (airootfs)
make_basefs() {
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" init
}

# Additional packages (airootfs)
make_packages() {
    set +e
    local _loadfilelist _pkg _file _excludefile _excludelist _pkglist

    #-- Detect package list to load --#
    # Add the files for each channel to the list of files to read.
    _loadfilelist=(
        # share packages
        $(ls "${script_path}"/channels/share/packages.${arch}/*.${arch} 2> /dev/null)
        "${script_path}/channels/share/packages.${arch}/lang/${locale_name}.${arch}"

        # channel packages
        $(ls ${channel_dir}/packages.${arch}/*.${arch} 2> /dev/null)
        "${channel_dir}/packages.${arch}/lang/${locale_name}.${arch}"

        # kernel packages
        "${script_path}/channels/share/packages.${arch}/kernel/${kernel}.${arch}"
        "${channel_dir}/packages.${arch}/kernel/${kernel}.${arch}"
    )

    # Plymouth package list
    if [[ "${boot_splash}" = true ]]; then
        _loadfilelist+=(
            $(ls "${script_path}"/channels/share/packages.${arch}/plymouth/*.${arch} 2> /dev/null)
            $(ls ${channel_dir}/packages.${arch}/plymouth/*.${arch} 2> /dev/null)
        )
    fi


    #-- Read package list --#
    # Read the file and remove comments starting with # and add it to the list of packages to install.
    for _file in ${_loadfilelist[@]}; do
        if [[ -f "${_file}" ]]; then
            msg_debug "Loaded package file ${_file}"
            _pkglist=( ${_pkglist[@]} "$(grep -h -v ^'#' ${_file})" )
        fi
    done

    #-- Read exclude list --#
    # Exclude packages from the share exclusion list
    _excludefile=(
        "${script_path}/channels/share/packages.${arch}/exclude"
        "${channel_dir}/packages.${arch}/exclude"
    )

    for _file in ${_excludefile[@]}; do
        if [[ -f "${_file}" ]]; then
            _excludelist=( ${_excludelist[@]} $(grep -h -v ^'#' "${_file}") )
        fi
    done

    #-- excludeに記述されたパッケージを除外 --#
    # _pkglistを_subpkglistにコピーしexcludeのパッケージを除外し再代入
    local _subpkglist=(${_pkglist[@]})
    unset _pkglist
    for _pkg in ${_subpkglist[@]}; do
        # もし変数_pkgの値が配列_excludelistに含まれていなかったらpkglistに追加する
        if [[ ! $(printf '%s\n' "${_excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
            _pkglist=(${_pkglist[@]} "${_pkg}")
        fi
    done
    unset _subpkglist

    #-- excludeされたパッケージを表示 --#
    if [[ -n "${_excludelist[*]}" ]]; then
        msg_debug "The following packages have been removed from the installation list."
        msg_debug "Excluded packages:" "${_excludelist[@]}"
    fi

    # Sort the list of packages in abc order.
    _pkglist=("$(for _pkg in ${_pkglist[@]}; do echo "${_pkg}"; done | sort)")

    set -e

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "# The list of packages that is installed in live cd.\n#\n\n" > "${work_dir}/packages.list"
    for _pkg in ${_pkglist[@]}; do
        echo ${_pkg} >> "${work_dir}/packages.list"
    done

    # Install packages on airootfs
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${_pkglist[@]}" install
}

# Additional packages (airootfs)
make_packages_file() {
    set +e
    #local _loadfilelist _pkg _file _excludefile _excludelist _pkglist

    #-- Detect package list to load --#
    # Add the files for each channel to the list of files to read.
    #_loadfilelist=(
    #    $(ls ${channel_dir}/packages.${arch}/*.${arch} 2> /dev/null)
    #    ${channel_dir}/packages.${arch}/lang/${locale_name}.${arch}
    #    $(ls "${script_path}"/channels/share/packages.${arch}/*.${arch} 2> /dev/null)
    #    "${script_path}"/channels/share/packages.${arch}/lang/${locale_name}.${arch}
    #)

    #ls "${channel_dir}/package_files.${arch}/*.pkg.*" > /dev/null 2>&1
    # Install packages on airootfs
    #if [ $? -ne 0 ]; then
    #    :
    #else
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${channel_dir}/package_files.${arch}/*.pkg.*" install_file
    #fi
    #ls "${script_path}/channels/share/package_files.${arch}/*.pkg.*" > /dev/null 2>&1
    #if [ $? -ne 0 ]; then
    #    :
    #else
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${script_path}/channels/share/package_files.${arch}/*.pkg.*" install_file
    #fi
}

make_packages_aur() {
    set +e

    local _loadfilelist _pkg _file _excludefile _excludelist _pkglist

    #-- Detect package list to load --#
    # Add the files for each channel to the list of files to read.
    _loadfilelist=(
        # share packages
        $(ls "${script_path}"/channels/share/packages_aur.${arch}/*.${arch} 2> /dev/null)
        "${script_path}/channels/share/packages_aur.${arch}/lang/${locale_name}.${arch}"

        # channel packages
        $(ls ${channel_dir}/packages_aur.${arch}/*.${arch} 2> /dev/null)
        "${channel_dir}/packages_aur.${arch}/lang/${locale_name}.${arch}"

        # kernel packages
        "${script_path}/channels/share/packages_aur.${arch}/kernel/${kernel}.${arch}"
        "${channel_dir}/packages_aur.${arch}/kernel/${kernel}.${arch}"
    )

    # Plymouth package list
    if [[ "${boot_splash}" = true ]]; then
        _loadfilelist+=(
            $(ls "${script_path}"/channels/share/packages_aur.${arch}/plymouth/*.${arch} 2> /dev/null)
            $(ls ${channel_dir}/packages_aur.${arch}/plymouth/*.${arch} 2> /dev/null)
        )
    fi

    if [[ ! -d "${channel_dir}/packages_aur.${arch}/" ]] && [[ ! -d "${script_path}/channels/share/packages_aur.${arch}/" ]]; then
        return
    fi

    #-- Read package list --#
    # Read the file and remove comments starting with # and add it to the list of packages to install.
    for _file in ${_loadfilelist[@]}; do
        if [[ -f "${_file}" ]]; then
            msg_debug "Loaded aur package file ${_file}."
            pkglist_aur=( ${pkglist_aur[@]} "$(grep -h -v ^'#' ${_file})" )
        fi
    done

    #-- Read exclude list --#
    # Exclude packages from the share exclusion list
    _excludefile=(
        "${script_path}/channels/share/packages_aur.${arch}/exclude"
        "${channel_dir}/packages_aur.${arch}/exclude"
    )

    for _file in ${_excludefile[@]}; do
        [[ -f "${_file}" ]] && _excludelist=(${_excludelist[@]} $(grep -h -v ^'#' "${_file}"))
    done

    # 現在のpkglistをコピーする
    _pkglist=(${pkglist[@]})
    unset pkglist
    for _pkg in ${_pkglist[@]}; do
        # もし変数_pkgの値が配列excludelistに含まれていなかったらpkglistに追加する
        if [[ ! $(printf '%s\n' "${_excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
            pkglist=(${pkglist[@]} "${_pkg}")
        fi
    done

    if [[ -n "${_excludelist[*]}" ]]; then
        msg_debug "The following packages have been removed from the aur list."
        msg_debug "Excluded packages:" "${_excludelist[@]}"
    fi

    # Sort the list of packages in abc order.
    pkglist_aur=("$( for _pkg in ${pkglist_aur[@]}; do echo "${_pkg}"; done | sort)")

    set -e

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "\n\n# AUR packages.\n#\n\n" >> "${work_dir}/packages.list"
    for _pkg in ${pkglist_aur[@]}; do echo ${_pkg} >> "${work_dir}/packages.list"; done

    # Build aur packages on airootfs
    for _file in "aur_install" "aur_prepare" "aur_remove" "pacls_gen_new" "pacls_gen_old"; do
        cp -r "${script_path}/system/aur_scripts/${_file}.sh" "${airootfs_dir}/root/${_file}.sh"
        chmod 755 "${airootfs_dir}/root/${_file}.sh"
    done

    local _aur_packages_ls_str=""
    for _pkg in ${pkglist_aur[@]}; do
        _aur_packages_ls_str="${_aur_packages_ls_str} ${_pkg}"
    done

    # Create user to build AUR
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/aur_prepare.sh ${_aur_packages_ls_str}" run

    # Check PKGBUILD
    for _pkg in ${pkglist_aur[@]}; do
        if [[ ! -f "${airootfs_dir}/aurbuild_temp/${_pkg}/PKGBUILD" ]]; then
            msg_error "PKGBUILD is missing. Please check if the package name ( ${_pkg} ) of AUR is correct." "1"
        fi
    done


    # Install dependent packages.
    local dependent_packages=""
    for _aur_pkg in ${pkglist_aur[@]}; do dependent_packages="${dependent_packages} $("${script_path}/system/aur_scripts/PKGBUILD_DEPENDS_SANDBOX.sh" "${script_path}/system/arch-pkgbuild-parser" "$(realpath "${airootfs_dir}/aurbuild_temp/${_aur_pkg}/PKGBUILD")")"; done
    [[ -n "${dependent_packages}" ]] && ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${dependent_packages}" install

    # Dump packages
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/pacls_gen_old.sh" run

    # Install makedependent packages.
    local makedependent_packages=""
    for _aur_pkg in ${pkglist_aur[@]}; do makedependent_packages="${makedependent_packages} $("${script_path}/system/aur_scripts/PKGBUILD_MAKEDEPENDS_SANDBOX.sh" "${script_path}/system/arch-pkgbuild-parser" "$(realpath "${airootfs_dir}/aurbuild_temp/${_aur_pkg}/PKGBUILD")")"; done
    [[ -n "${makedependent_packages}" ]] && ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${makedependent_packages}" install


    # Dump packages
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/pacls_gen_new.sh" run

    # Build the package using makepkg.
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/aur_install.sh ${_aur_packages_ls_str}" run

    # Install the built package file.
    for _pkg in ${pkglist_aur[@]}; do
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${airootfs_dir}/aurbuild_temp/${_pkg}/*.pkg.tar.*" install_file
    done

    # Remove packages
    delete_pkg_list=(`comm -13 --nocheck-order "${airootfs_dir}/paclist_old" "${airootfs_dir}/paclist_new" |xargs`)
    for _dlpkg in ${delete_pkg_list[@]}; do
        unshare --fork --pid pacman -r "${airootfs_dir}" -R --noconfirm ${_dlpkg}
    done

    # Remove the user created for the build.
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}"  -D "${install_dir}" -r "/root/aur_remove.sh" run

    # Remove scripts
    remove "${airootfs_dir}/root/"{"aur_install","aur_prepare","aur_remove","pacls_gen_new","pacls_gen_old"}".sh"
}

# Customize installation (airootfs)
make_customize_airootfs() {
    # Overwrite airootfs with customize_airootfs.
    local _copy_airootfs

    _copy_airootfs() {
        local _dir="${1%/}"
        if [[ -d "${_dir}" ]]; then
            cp -af "${_dir}"/* "${airootfs_dir}"
        fi
    }

    _copy_airootfs "${script_path}/channels/share/airootfs.any"
    _copy_airootfs "${script_path}/channels/share/airootfs.${arch}"
    _copy_airootfs "${channel_dir}/airootfs.any"
    _copy_airootfs "${channel_dir}/airootfs.${arch}"

    # Replace /etc/mkinitcpio.conf if Plymouth is enabled.
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-plymouth.conf" "${airootfs_dir}/etc/mkinitcpio.conf"
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
    local _airootfs_script_options
    _airootfs_script_options="-p '${password}' -k '${kernel} ${kernel_filename} ${kernel_mkinitcpio_profile}' -u '${username}' -o '${os_name}' -i '${install_dir}' -s '${usershell}' -a '${arch}' -g '${locale_gen_name}' -l '${locale_name}' -z '${locale_time}' -t ${theme_name}"
    [[ ${boot_splash} = true ]] && _airootfs_script_options="${_airootfs_script_options} -b"
    [[ ${debug} = true ]]       && _airootfs_script_options="${_airootfs_script_options} -d"
    [[ ${bash_debug} = true ]]  && _airootfs_script_options="${_airootfs_script_options} -x"
    [[ ${rebuild} = true ]]     && _airootfs_script_options="${_airootfs_script_options} -r"

    # X permission
    local chmod_755
    chmod_755() {
        for _file in ${@}; do
            if [[ -f "$_file" ]]; then chmod 755 "${_file}" ;fi
        done
    }

    chmod_755 "${airootfs_dir}/root/customize_airootfs.sh" "${airootfs_dir}/root/customize_airootfs.sh" "${airootfs_dir}/root/customize_airootfs_${channel_name}.sh" "${airootfs_dir}/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh"

    # Execute customize_airootfs.sh.
    ${mkalteriso} ${mkalteriso_option} \
    -w "${work_dir}/${arch}" \
    -C "${work_dir}/pacman-${arch}.conf" \
    -D "${install_dir}" \
    -r "/root/customize_airootfs.sh ${_airootfs_script_options}" \
    run

    if [[ -f "${airootfs_dir}/root/customize_airootfs_${channel_name}.sh" ]]; then
        ${mkalteriso} ${mkalteriso_option} \
        -w "${work_dir}/${arch}" \
        -C "${work_dir}/pacman-${arch}.conf" \
        -D "${install_dir}" \
        -r "/root/customize_airootfs_${channel_name}.sh ${_airootfs_script_options}" \
        run
    elif [[ -f "${airootfs_dir}/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh" ]]; then
        ${mkalteriso} ${mkalteriso_option} \
        -w "${work_dir}/${arch}" \
        -C "${work_dir}/pacman-${arch}.conf" \
        -D "${install_dir}" \
        -r "/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh ${_airootfs_script_options}" \
        run
    fi

    # Delete customize_airootfs.sh.
    remove "${airootfs_dir}/root/customize_airootfs.sh"
    remove "${airootfs_dir}/root/customize_airootfs_${channel_name}.sh"

    # /root permission
    # https://github.com/archlinux/archiso/commit/d39e2ba41bf556674501062742190c29ee11cd59
    chmod -f 750 "${airootfs_dir}/root"
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${airootfs_dir}/etc/initcpio/hooks"
    mkdir -p "${airootfs_dir}/etc/initcpio/install"
    for _hook in "archiso" "archiso_shutdown" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${airootfs_dir}/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${airootfs_dir}/etc/initcpio/install"
    done
    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" "${airootfs_dir}/etc/initcpio/install/archiso_shutdown"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${airootfs_dir}/etc/initcpio/install"
    cp "${script_path}/system/initcpio/archiso_shutdown" "${airootfs_dir}/etc/initcpio"
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso-plymouth.conf" "${airootfs_dir}/etc/mkinitcpio-archiso.conf"
    else
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso.conf" "${airootfs_dir}/etc/mkinitcpio-archiso.conf"
    fi
    gnupg_fd=
    if [[ "${gpg_key}" ]]; then
      gpg --export "${gpg_key}" >"${work_dir}/gpgkey"
      exec 17<>"${work_dir}/gpgkey"
    fi

    ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/${kernel_filename} -g /boot/archiso.img" run

    if [[ "${gpg_key}" ]]; then
        exec 17<&-
    fi
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p "${isofs_dir}/${install_dir}/boot/${arch}"
    cp "${airootfs_dir}/boot/archiso.img" "${isofs_dir}/${install_dir}/boot/${arch}/archiso.img"
    cp "${airootfs_dir}/boot/${kernel_filename}" "${isofs_dir}/${install_dir}/boot/${arch}/${kernel_filename}"
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    if [[ -e "${airootfs_dir}/boot/memtest86+/memtest.bin" ]]; then
        cp "${airootfs_dir}/boot/memtest86+/memtest.bin" "${isofs_dir}/${install_dir}/boot/memtest"
        cp "${airootfs_dir}/usr/share/licenses/common/GPL2/license.txt" "${isofs_dir}/${install_dir}/boot/memtest.COPYING"
    fi

    local _ucode_image
    msg_info "Preparing microcode for the ISO 9660 file system..."

    for _ucode_image in {intel-uc.img,intel-ucode.img,amd-uc.img,amd-ucode.img,early_ucode.cpio,microcode.cpio}; do
        if [[ -e "${airootfs_dir}/boot/${_ucode_image}" ]]; then
            install -m 0644 -- "${airootfs_dir}/boot/${_ucode_image}" "${isofs_dir}/${install_dir}/boot/"
            if [[ -e "${airootfs_dir}/usr/share/licenses/${_ucode_image%.*}/" ]]; then
                install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/licenses/${_ucode_image%.*}/"
                install -m 0644 -- "${airootfs_dir}/usr/share/licenses/${_ucode_image%.*}/"* "${isofs_dir}/${install_dir}/boot/licenses/${_ucode_image%.*}/"
            fi
        fi
    done
    msg_info "Done!"
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    _uname_r="$(file -b ${airootfs_dir}/boot/${kernel_filename} | awk 'f{print;f=0} /version/{f=1}' RS=' ')"
    mkdir -p "${isofs_dir}/${install_dir}/boot/syslinux"

    # 一時ディレクトリに設定ファイルをコピー
    mkdir -p "${work_dir}/${arch}/syslinux/"
    cp -a "${script_path}/syslinux/"* "${work_dir}/${arch}/syslinux/"
    if [[ -d "${channel_dir}/syslinux" ]] && [[ "${customized_syslinux}" = true ]]; then
        cp -af "${channel_dir}/syslinux"* "${work_dir}/${arch}/syslinux/"
    fi

    # copy all syslinux config to work dir
    for _cfg in ${work_dir}/${arch}/syslinux/*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%ARCH%|${arch}|g;
             s|%INSTALL_DIR%|${install_dir}|g" "${_cfg}" > "${isofs_dir}/${install_dir}/boot/syslinux/${_cfg##*/}"
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
        remove "${isofs_dir}/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}_${_no_use_config_name}.cfg"
        mv "${isofs_dir}/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}_${_use_config_name}.cfg" "${isofs_dir}/${install_dir}/boot/syslinux/archiso_${_pxe_or_sys}.cfg"
    done

    # Set syslinux wallpaper
    if [[ -f "${channel_dir}/splash.png" ]]; then
        cp "${channel_dir}/splash.png" "${isofs_dir}/${install_dir}/boot/syslinux"
    else
        cp "${script_path}/syslinux/splash.png" "${isofs_dir}/${install_dir}/boot/syslinux"
    fi

    # Remove rescue config
    if [[ "${norescue_entry}" = true ]]; then
        remove "${isofs_dir}/${install_dir}/boot/syslinux/archiso_sys_rescue.cfg"
        sed -i "s|$(cat "${isofs_dir}/${install_dir}/boot/syslinux/archiso_sys_load.cfg" | grep "archiso_sys_rescue")||g" "${isofs_dir}/${install_dir}/boot/syslinux/archiso_sys_load.cfg" 
    fi

    # copy files
    cp "${work_dir}"/${arch}/airootfs/usr/lib/syslinux/bios/*.c32 "${isofs_dir}/${install_dir}/boot/syslinux"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/lpxelinux.0" "${isofs_dir}/${install_dir}/boot/syslinux"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/memdisk" "${isofs_dir}/${install_dir}/boot/syslinux"
    mkdir -p "${isofs_dir}/${install_dir}/boot/syslinux/hdt"
    gzip -c -9 "${airootfs_dir}/usr/share/hwdata/pci.ids" > "${isofs_dir}/${install_dir}/boot/syslinux/hdt/pciids.gz"
    gzip -c -9 "${airootfs_dir}/usr/lib/modules/${_uname_r}/modules.alias" > "${isofs_dir}/${install_dir}/boot/syslinux/hdt/modalias.gz"
}

# Prepare /isolinux
make_isolinux() {
    mkdir -p "${isofs_dir}/isolinux"

    sed "s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/system/isolinux.cfg" > "${isofs_dir}/isolinux/isolinux.cfg"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/isolinux.bin" "${isofs_dir}/isolinux/"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/isohdpfx.bin" "${isofs_dir}/isolinux/"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/ldlinux.c32" "${isofs_dir}/isolinux/"
}

# Prepare /EFI
make_efi() {
    mkdir -p "${isofs_dir}/EFI/boot"
    (
        local __bootfile="$(basename "$(ls "${airootfs_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"
        cp "${airootfs_dir}/usr/lib/systemd/boot/efi/${__bootfile}" "${isofs_dir}/EFI/boot/${__bootfile#systemd-}"
    )

    mkdir -p "${isofs_dir}/loader/entries"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/loader/loader.conf" > "${isofs_dir}/loader/loader.conf"

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%KERNEL_FILENAME%|${kernel_filename}|g;
         s|%ARCH%|${arch}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/efiboot/loader/entries/archiso-usb.conf" > "${isofs_dir}/loader/entries/archiso-${arch}.conf"

    # edk2-shell based UEFI shell
    local _efi_shell _efi_shell_arch
    for _efi_shell in "${work_dir}"/${arch}/airootfs/usr/share/edk2-shell/*; do
        _efi_shell_arch="$(basename ${_efi_shell})"
        cp "${_efi_shell}/Shell_Full.efi" "${isofs_dir}/EFI/shell_${_efi_shell_arch}.efi"
        cat - > "${isofs_dir}/loader/entries/uefi-shell-${_efi_shell_arch}.conf" << EOF
title  UEFI Shell ${_efi_shell_arch}
efi    /EFI/shell_${_efi_shell_arch}.efi

EOF
    done
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {
    mkdir -p "${isofs_dir}/EFI/alteriso"
    truncate -s 128M "${isofs_dir}/EFI/alteriso/efiboot.img"
    mkfs.fat -n ARCHISO_EFI "${isofs_dir}/EFI/alteriso/efiboot.img"

    mkdir -p "${work_dir}/efiboot"
    mount "${isofs_dir}/EFI/alteriso/efiboot.img" "${work_dir}/efiboot"

    mkdir -p "${work_dir}/efiboot/EFI/alteriso"

    cp "${isofs_dir}/${install_dir}/boot/${arch}/${kernel_filename}" "${work_dir}/efiboot/EFI/alteriso/${arch}/${kernel_filename}.efi"
    cp "${isofs_dir}/${install_dir}/boot/${arch}/archiso.img" "${work_dir}/efiboot/EFI/alteriso/${arch}/archiso.img"

    local _ucode_image
    for _ucode_image in "${airootfs_dir}/boot/"{intel-uc.img,intel-ucode.img,amd-uc.img,amd-ucode.img,early_ucode.cpio,microcode.cpio}; do
        [[ -e "${_ucode_image}" ]] && cp "${_ucode_image}" "${work_dir}/efiboot/EFI/alteriso/"
    done

    mkdir -p "${work_dir}/efiboot/EFI/boot"
    (
        local __bootfile="$(basename "$(ls "${airootfs_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"
        cp "${airootfs_dir}/usr/lib/systemd/boot/efi/${__bootfile}" "${work_dir}/efiboot/EFI/boot/${__bootfile#systemd-}"
    )

    mkdir -p "${work_dir}/efiboot/loader/entries"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/loader/loader.conf" > "${work_dir}/efiboot/loader/loader.conf"
    cp "${isofs_dir}/loader/entries/uefi-shell"* "${work_dir}/efiboot/loader/entries/"


    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%KERNEL_FILENAME%|${kernel_filename}|g;
         s|%ARCH%|${arch}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
    "${script_path}/efiboot/loader/entries/archiso-cd.conf" > "${work_dir}/efiboot/loader/entries/archiso-${arch}.conf"

    cp "${isofs_dir}/EFI/shell"*".efi" "${work_dir}/efiboot/EFI/"

    umount -d "${work_dir}/efiboot"
}

# Compress tarball
make_tarball() {
    cp -a -l -f "${airootfs_dir}" "${work_dir}"

    if [[ -f "${airootfs_dir}/root/optimize_for_tarball.sh" ]]; then
        chmod 755 "${airootfs_dir}/root/optimize_for_tarball.sh"
        # Execute optimize_for_tarball.sh.
        ${mkalteriso} ${mkalteriso_option} \
        -w "${work_dir}/${arch}" \
        -C "${work_dir}/pacman-${arch}.conf" \
        -D "${install_dir}" \
        -r "/root/optimize_for_tarball.sh" \
        run
    fi

    ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r "mkinitcpio -p ${kernel_mkinitcpio_profile}" run

    remove "${airootfs_dir}/root/optimize_for_tarball.sh"

    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -P "${iso_publisher}" -A "${iso_application}" -o "${out_dir}" tarball "$(echo ${iso_filename} | sed 's/\.[^\.]*$//').tar.xz"

    remove "${work_dir}/airootfs"
    if [[ "${noiso}" = true ]]; then
        msg_info "The password for the live user and root is ${password}."
    fi
}


# Build airootfs filesystem image
make_prepare() {
    cp -a -l -f "${airootfs_dir}" "${work_dir}"
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" pkglist
    pacman -Q --sysroot "${work_dir}/airootfs" > "${work_dir}/packages-full.list"
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} -c "${sfs_comp}" -t "${sfs_comp_opt}" prepare
    remove "${work_dir}/airootfs"

    if [[ "${cleaning}" = true ]]; then
        remove "${airootfs_dir}"
    fi

    # iso version info
    if [[ "${include_info}" = true ]]; then
        local _write_info_file _info_file="${isofs_dir}/alteriso-info"
        _write_info_file () {
            echo "${@}" >> "${_info_file}"
        }
        rm -rf "${_info_file}"; touch "${_info_file}"

        _write_info_file "Developer      : ${iso_publisher}"
        _write_info_file "OS Name        : ${iso_application}"
        _write_info_file "Architecture   : ${arch}"
        if [[ -d "${script_path}/.git" ]] && [[ "${gitversion}" = false ]]; then
            _write_info_file "Version        : ${iso_version}-$(git rev-parse --short HEAD)"
        else
        _write_info_file "Version        : ${iso_version}"
        fi
        _write_info_file "Channel   name : ${channel_name}"
        _write_info_file "Live user name : ${username}"
        _write_info_file "Live user pass : ${password}"
        _write_info_file "Kernel    name : ${kernel}"
        if [[ "${boot_splash}" = true ]]; then
            _write_info_file "Plymouth       : Yes"
        else
            _write_info_file "Plymouth       : No"
        fi
    fi
}

# Build ISO
make_iso() {
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -P "${iso_publisher}" -A "${iso_application}" -o "${out_dir}" iso "${iso_filename}"
    msg_info "The password for the live user and root is ${password}."
}

# Parse files
parse_files() {
    #-- ロケールを解析、設定 --#
    local _get_locale_line_number _locale_config_file _locale_name_list _locale_line_number _locale_config_line

    # 選択されたロケールの設定が描かれた行番号を取得
    _locale_config_file="${script_path}/system/locale-${arch}"
    _locale_name_list=($(cat "${_locale_config_file}" | grep -h -v ^'#' | getclm 1))
    _get_locale_line_number() {
        local _lang _count=0
        for _lang in ${_locale_name_list[@]}; do
            _count=$(( _count + 1 ))
            if [[ "${_lang}" = "${locale_name}" ]]; then echo "${_count}"; return 0; fi
        done
        echo -n "failed"
    }
    _locale_line_number="$(_get_locale_line_number)"

    # 不正なロケール名なら終了する
    [[ "${_locale_line_number}" = "failed" ]] && msg_error "${locale_name} is not a valid language." "1"

    # ロケール設定ファイルから該当の行を抽出
    _locale_config_line=($(cat "${_locale_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_locale_line_number}" | tail -n 1))

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
    locale_name="${_locale_config_line[0]}"
    locale_gen_name="${_locale_config_line[1]}"
    locale_version="${_locale_config_line[2]}"
    locale_time="${_locale_config_line[3]}"
    locale_fullname="${_locale_config_line[4]}"


    #-- カーネルを解析、設定 --#
    local _kernel_config_file _kernel_name_list _kernel_line _get_kernel_line _kernel_config_line

    # 選択されたカーネルの設定が描かれた行番号を取得
    _kernel_config_file="${script_path}/system/kernel-${arch}"
    _kernel_name_list=($(cat "${_kernel_config_file}" | grep -h -v ^'#' | getclm 1))
    _get_kernel_line() {
        local _kernel _count=0
        for _kernel in ${_kernel_name_list[@]}; do
            _count=$(( _count + 1 ))
            if [[ "${_kernel}" = "${kernel}" ]]; then echo "${_count}"; return 0; fi
        done
        echo -n "failed"
        return 0
    }
    _kernel_line="$(_get_kernel_line)"

    # 不正なカーネル名なら終了する
    [[ "${_kernel_line}" = "failed" ]] && msg_error "Invalid kernel ${kernel}" "1"

    # カーネル設定ファイルから該当の行を抽出
    _kernel_config_line=($(cat "${_kernel_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_kernel_line}" | tail -n 1))

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
    kernel="${_kernel_config_line[0]}"
    kernel_filename="${_kernel_config_line[1]}"
    kernel_mkinitcpio_profile="${_kernel_config_line[2]}"
}


# Parse options
ARGUMENT="${@}"
_opt_short="a:bc:deg:hjk:l:o:p:rt:u:w:x"
_opt_long="arch:,boot-splash,comp-type:,debug,cleaning,cleanup,gpgkey:,help,lang:,japanese,kernel:,out:,password:,comp-opts:,user:,work:,bash-debug,nocolor,noconfirm,nodepend,gitversion,shmkalteriso,msgdebug,noloopmod,tarball,noiso,noaur,nochkver,channellist,config:,noefi"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${DEFAULT_ARGUMENT} ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
msg_debug "Argument: ${OPT}"
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
                *) msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        -d | --debug)
            debug=true
            shift 1
            ;;
        -e | --cleaning | --cleanup)
            cleaning=true
            shift 1
            ;;
        -g | --gpgkey)
            gpg_key="$2"
            shift 2
            ;;
        -h | --help)
            _usage
            exit 0
            ;;
        -j | --japanese)
            msg_error "This option is obsolete in AlterISO 3. To use Japanese, use \"-l ja\"." "1"
            ;;
        -k | --kernel)
            kernel="${2}"
            shift 2
            ;;
        -l | --lang)
            locale_name="${2}"
            shift 2
            ;;
        -o | --out)
            out_dir="${2}"
            shift 2
            ;;
        -p | --password)
            customized_password=true
            password="${2}"
            shift 2
            ;;
        -r | --tarball)
            tarball=true
            shift 1
            ;;
        -t | --comp-opts)
            if [[ "${2}" = "reset" ]]; then
                sfs_comp_opt=""
            else
                sfs_comp_opt="${2}"
            fi
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
                msg_error "There is no git directory. You need to use git clone to use this feature." "1"
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
        --noefi)
            noefi=true
            shift 1
            ;;
        --channellist)
            show_channel_list
            exit 0
            ;;
        --config)
            source "${2}"
             shift 2
             ;;
        --)
            shift
            break
            ;;
        *)
            msg_error "Invalid argument '${1}'"
            _usage 1
            ;;
    esac
done


# Check root.
if [[ ${EUID} -ne 0 ]]; then
    msg_warn "This script must be run as root." >&2
    msg_warn "Re-run 'sudo ${0} ${DEFAULT_ARGUMENT} ${ARGUMENT}'"
    sudo ${0} ${DEFAULT_ARGUMENT} ${ARGUMENT}
    exit "${?}"
fi

unset DEFAULT_ARGUMENT ARGUMENT

# Show config message
msg_debug "Use the default configuration file (${defaultconfig})."
[[ -f "${script_path}/custom.conf" ]] && msg_debug "The default settings have been overridden by custom.conf"

# Set rebuild config file
rebuildfile="${work_dir}/alteriso_config"

set +eu

# Check for a valid channel name
if [[ -n "${1}" ]]; then
    case "$(bash "${script_path}/tools/channel.sh" -n -m check "${1}")" in
        "incorrect")
            msg_error "Invalid channel ${1}" "1"
            ;;
        "directory")
            channel_dir="${1}"
            channel_name="$(basename "${1%/}")"
            ;;
        "correct")
            channel_dir="${script_path}/channels/${1}"
            channel_name="${1}"
            ;;
    esac
fi

# Set for special channels
if [[ -d "${channel_dir}.add" ]]; then
    channel_name="${1}"
    channel_dir="${channel_dir}.add"
elif [[ "${channel_name}" = "rebuild" ]]; then
    if [[ -f "${rebuildfile}" ]]; then
        rebuild=true
    else
        msg_error "The previous build information is not in the working directory." "1"
    fi
elif [[ "${channel_name}" = "clean" ]]; then
   "${script_path}/tools/clean.sh" -w $(realpath "${work_dir}") $([[ "${debug}" = true ]] && echo -n "-d")
    exit 0
else
    channel_dir="${script_path}/channels/${channel_name}"
fi

# Check channel version
if [[ ! "${channel_name}" = "rebuild" ]]; then
    msg_debug "channel path is ${channel_dir}"
    if [[ ! "$(cat "${channel_dir}/alteriso" 2> /dev/null)" = "alteriso=${alteriso_version}" ]] && [[ "${nochkver}" = false ]]; then
        msg_error "This channel does not support Alter ISO 3."
        if [[ -d "${script_path}/.git" ]]; then
            msg_error "Please run \"git checkout alteriso-2\"" "1"
        else
            msg_error "Please download Alter ISO 2 here.\nhttps://github.com/FascodeNet/alterlinux/archive/alteriso-2.zip" "1"
        fi
    fi
fi

parse_files

set -eu

prepare_env
prepare_build
show_settings
run_once make_pacman_conf
run_once make_basefs
run_once make_packages
#run_once make_packages_file
[[ "${noaur}" = false ]] && run_once make_packages_aur
run_once make_customize_airootfs
run_once make_setup_mkinitcpio
if [[ "${noiso}" = false ]] ; then
    run_once make_syslinux
    run_once make_isolinux
fi
run_once make_boot
[[ "${noiso}" = false ]] && run_once make_prepare
run_once make_boot_extra
if [[ "${noiso}" = false ]] && [[ "${noefi}" = false ]]; then
    run_once make_efi
    run_once make_efiboot
fi
[[ "${tarball}" = true ]] && run_once make_tarball
[[ "${noiso}" = false ]] && run_once make_iso
[[ "${cleaning}" = true ]] && "${script_path}/tools/clean.sh" -o -w "$(realpath "${work_dir}")" $([[ "${debug}" = true ]] && echo -n "-d")

exit 0

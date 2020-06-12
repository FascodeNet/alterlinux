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

set -e
set -u

# Internal config
# Do not change these values.
script_path="$(readlink -f ${0%/*})"
defaultconfig="${script_path}/default.conf"


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
    local backcolor
    local textcolor
    local decotypes
    local echo_opts
    local arg
    local OPTIND
    local OPT

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
        echo ${echo_opts} "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${@}\e[m"
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
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[build.sh]')    $( echo_color -t '32' 'Info') ${@}"
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
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[build.sh]') $( echo_color -t '33' 'Warning') ${@}" >&2
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
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    if [[ ${debug} = true ]]; then
        echo ${echo_opts} "$( echo_color -t '36' '[build.sh]')   $( echo_color -t '35' 'Debug') ${@}"
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
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    local OPTARG
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
    echo " General options:"
    echo
    echo "    -b | --boot-splash           Enable boot splash"
    echo "                                  Default: disable"
    echo "    -j | --japanese              Enable Japanese mode."
    echo "                                  Default: disable"
    echo "    -l | --cleanup               Enable post-build cleaning."
    echo "                                  Default: disable"
    echo "    -d | --debug                 Enable debug messages."
    echo "                                  Default: disable"
    echo "    -x | --bash-debug            Enable bash debug mode.(set -xv)"
    echo "                                  Default: disable"
    echo "    -h | --help                  This help message and exit."
    echo
    echo "    -a | --arch <arch>           Set iso architecture."
    echo "                                  Default: ${arch}"
    echo "    -c | <comp_type>             Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)"
    echo "                                  Default: ${sfs_comp}"
    echo "    -g | --gpgkey <key>          Set gpg key"
    echo "                                  Default: ${gpg_key}"
    echo "    -k | --kernel <kernel>       Set special kernel type.See below for available kernels."
    echo "                                  Default: ${kernel}"
    echo "    -o | --out <out_dir>         Set the output directory"
    echo "                                  Default: ${out_dir}"
    echo "    -p | --password <password>   Set a live user password"
    echo "                                  Default: ${password}"
    echo "    -t | --comp-opts <options>   Set compressor-specific options."
    echo "                                  Default: empty"
    echo "    -u | --use <username>        Set user name."
    echo "                                  Default: ${username}"
    echo "    -w | --work <work_dir>       Set the working directory"
    echo "                                  Default: ${work_dir}"
    echo
    echo "    --gitversion                 Add Git commit hash to image file version"
    echo "    --msgdebug                   Enables output debugging."
    echo "    --nocolor                    Does not output colored output."
    echo "    --noconfirm                  Does not check the settings before building."
    echo "    --nodepend                   Do not check package dependencies before building."
    echo "    --shmkalteriso               Use the shell script version of mkalteriso."
    echo
    echo "A list of kernels available for each architecture."
    echo
    local kernel
    local list
    for list in $(ls ${script_path}/system/kernel_list-*); do
        echo " ${list#${script_path}/system/kernel_list-}:"
        echo -n "    "
        for kernel in $(grep -h -v ^'#' ${list}); do
            echo -n "${kernel} "
        done
        echo
    done
    echo
    echo "You can switch between installed packages, files included in images, etc. by channel."
    echo
    echo " Channel:"
    for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9 }'); do
        if [[ -n $(ls "${script_path}"/channels/${i}) ]]; then
            if [[ ! ${i} = "share" ]]; then
                if [[ ! $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                    if [[ ! -d "${script_path}/channels/${i}.add" ]]; then
                        channel_list="${channel_list[@]} ${i}"
                    fi
                else
                    channel_list="${channel_list[@]} ${i}"
                fi
            fi
        fi
    done
    channel_list="${channel_list[@]} rebuild"
    for _channel in ${channel_list[@]}; do
        if [[ -f "${script_path}/channels/${_channel}/description.txt" ]]; then
            description=$(cat "${script_path}/channels/${_channel}/description.txt")
        elif [[ "${_channel}" = "rebuild" ]]; then
            description="Rebuild using the settings of the previous build."
        else
            description="This channel does not have a description.txt."
        fi
        if [[ $(echo "${_channel}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
            echo -ne "    $(echo ${_channel} | sed 's/\.[^\.]*$//')"
            for i in $( seq 1 $(( 33 - ${#_channel} )) ); do
                echo -ne " "
            done
        else
            echo -ne "    ${_channel}"
            for i in $( seq 1 $(( 29 - ${#_channel} )) ); do
                echo -ne " "
            done
        fi
        echo -ne "${description}\n"
    done

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
    if [[ ! -e "${work_dir}/build.${1}_${arch}" ]]; then
        _msg_debug "Running $1 ..."
        "$1"
        touch "${work_dir}/build.${1}_${arch}"
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
    local _list
    local _file
    _list=($(echo "$@"))
    for _file in "${_list[@]}"; do
        _msg_debug "Removeing ${_file}"
        if [[ -f ${_file} ]]; then
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            rm -rf "${_file}"
        fi
    done
}


# 強制終了時にアンマウント
umount_trap() {
    local status=${?}
    umount_chroot
    _msg_error "It was killed by the user."
    _msg_error "The process may not have completed successfully."
    exit ${status}
}


# 作業ディレクトリを削除
remove_work() {
    remove "$(ls ${work_dir}/* | grep "build.make")"
    remove "${work_dir}"/pacman-*.conf
    remove "${work_dir}/efiboot"
    remove "${work_dir}/iso"
    remove "${work_dir}/${arch}"
    remove "${work_dir}/packages.list"
    remove "${work_dir}/packages-full.list"
    remove "${rebuildfile}"
    if [[ -z $(ls $(realpath "${work_dir}")/* 2>/dev/null) ]]; then
        remove ${work_dir}
    fi
}


# Preparation for build
prepare_build() {
    # Build mkalteriso
    if [[ "${shmkalteriso}" = false ]]; then
        mkalteriso="${script_path}/system/mkalteriso"
        cd "${script_path}"
        make mkalteriso
        cd - > /dev/null 2>&1
    else
        mkalteriso="${script_path}/system/mkalteriso.sh"
    fi

    # Create a working directory.
    [[ ! -d "${work_dir}" ]] && mkdir -p "${work_dir}"


    # Check work dir
    if [[ -n $(ls -a "${work_dir}" 2> /dev/null | grep -xv ".." | grep -xv ".") ]] && [[ ! "${rebuild}" = true ]]; then
        umount_chroot
        _msg_info "Deleting the contents of ${work_dir}..."
        remove "${work_dir%/}"/*
    fi


    # 強制終了時に作業ディレクトリを削除する
    local trap_remove_work
    trap_remove_work() {
        local status=${?}
        echo
        remove_work
        exit ${status}
    }
    trap 'trap_remove_work' 1 2 3 15

    # Save build options
    local save_var
    save_var() {
        local out_file="${rebuildfile}"
        local i
        echo "#!/usr/bin/env bash" > "${out_file}"
        echo "# Build options are stored here." >> "${out_file}"
        for i in ${@}; do
            echo -n "${i}=" >> "${out_file}"
            echo -n '"' >> "${out_file}"
            eval echo -n '$'{${i}} >> "${out_file}"
            echo '"' >> "${out_file}"
        done
    }
    if [[ ${rebuild} = false ]]; then
        # If there is pacman.conf for each channel, use that for building
        if [[ -f "${script_path}/channels/${channel_name}/pacman-${arch}.conf" ]]; then
            build_pacman_conf="${script_path}/channels/${channel_name}/pacman-${arch}.conf"
        fi


        # If there is config for each channel. load that.
        if [[ -f "${script_path}/channels/${channel_name}/config.any" ]]; then
            source "${script_path}/channels/${channel_name}/config.any"
            _msg_debug "The settings have been overwritten by the ${script_path}/channels/${channel_name}/config.any"
        fi

        if [[ -f "${script_path}/channels/${channel_name}/config.${arch}" ]]; then
            source "${script_path}/channels/${channel_name}/config.${arch}"
            _msg_debug "The settings have been overwritten by the ${script_path}/channels/${channel_name}/config.${arch}"
        fi


        # Set username
        if [[ "${customized_username}" = false ]]; then
            username="${defaultusername}"
        fi

        # Save the value of the variable for use in rebuild.
        save_var \
            arch \
            os_name \
            iso_name \
            iso_label \
            iso_publisher \
            iso_application \
            iso_version \
            install_dir \
            work_dir \
            out_dir \
            gpg_key \
            mkalteriso_option \
            password \
            boot_splash \
            kernel \
            theme_name \
            theme_pkg \
            sfs_comp \
            sfs_comp_opt \
            debug \
            japanese \
            channel_name \
            cleaning \
            username mkalteriso \
            usershell \
            shmkalteriso \
            nocolor \
            build_pacman_conf \
            defaultconfig \
            msgdebug \
            defaultusername \
            customized_username
    else
        # Load rebuild file
        source "${work_dir}/build_options"

        # Delete the lock file.
        # remove "$(ls ${work_dir}/* | grep "build.make")"
    fi


    # Unmount
    local mount
    for mount in $(mount | awk '{print $3}' | grep $(realpath ${work_dir})); do
        _msg_info "Unmounting ${mount}"
        umount "${mount}"
    done


    # Generate iso file name.
    local _channel_name
    if [[ $(echo "${channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
        _channel_name="$(echo ${channel_name} | sed 's/\.[^\.]*$//')"
    else
        _channel_name="${channel_name}"
    fi
    if [[ "${japanese}" = true ]]; then
        _channel_name="${_channel_name}-jp"
    fi
    iso_filename="${iso_name}-${_channel_name}-${iso_version}-${arch}.iso"
    _msg_debug "Iso filename is ${iso_filename}"


     # Check packages
    if [[ "${nodepend}" = false ]] && [[ "${arch}" = $(uname -m) ]] ; then
        local installed_pkg
        local installed_ver
        local check_pkg
        local check_failed=false
        local pkg

        installed_pkg=($(pacman -Q | awk '{print $1}'))
        installed_ver=($(pacman -Q | awk '{print $2}'))

        check_pkg() {
            local i
            local ver
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
                    echo
                    ;;
                "not") _msg_error "${pkg} is not installed." ; check_failed=true ;;
                "norepo") _msg_warn "${pkg} is not a repository package." ;;
                "installed") [[ ${debug} = true ]] && echo -ne " $(pacman -Q ${pkg} | awk '{print $2}')\n" ;;
            esac
        done

        if [[ "${check_failed}" = true ]]; then
            exit 1
        fi
    fi

    # Load loop kernel module
    if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
        _msg_error "The currently running kernel module could not be found."
        _msg_error "Probably the system kernel has been updated."
        _msg_error "Reboot your system to run the latest kernel." "1"
    fi
    if [[ -z $(lsmod | awk '{print $1}' | grep -x "loop") ]]; then
        sudo modprobe loop
    fi
}


# Show settings.
show_settings() {
    echo
    _msg_info "mkalteriso path is ${mkalteriso}"
    echo
    if [[ "${boot_splash}" = true ]]; then
        _msg_info "Boot splash is enabled."
        _msg_info "Theme is used ${theme_name}."
    fi
    _msg_info "Use the ${kernel} kernel."
    _msg_info "Live username is ${username}."
    _msg_info "Live user password is ${password}."
    _msg_info "The compression method of squashfs is ${sfs_comp}."
    if [[ $(echo "${channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
        _msg_info "Use the $(echo ${channel_name} | sed 's/\.[^\.]*$//') channel."
    else
        _msg_info "Use the ${channel_name} channel."
    fi
    [[ "${japanese}" = true ]] && _msg_info "Japanese mode has been activated."
    _msg_info "Build with architecture ${arch}."
    echo
    if [[ ${noconfirm} = false ]]; then
        echo "Press Enter to continue or Ctrl + C to cancel."
        read
    else
        :
        #sleep 3
    fi
    trap 1 2 3 15
    trap 'umount_trap' 1 2 3 15
}


# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    _msg_debug "Use ${build_pacman_conf}"
    local _cache_dirs
    _cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${_cache_dirs[@]})|g" ${build_pacman_conf} > "${work_dir}/pacman-${arch}.conf"
}

# Base installation, plus needed packages (airootfs)
make_basefs() {
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" init
    # ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "haveged intel-ucode amd-ucode memtest86+ mkinitcpio-nfs-utils nbd zsh efitools" install
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "bash haveged intel-ucode amd-ucode mkinitcpio-nfs-utils nbd efitools" install

    # Install plymouth.
    if [[ "${boot_splash}" = true ]]; then
        if [[ -n "${theme_pkg}" ]]; then
            ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "plymouth ${theme_pkg}" install
        else
            ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "plymouth" install
        fi
    fi

    # Install kernel.
    if [[ ! "${kernel}" = "core" ]]; then
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "linux-${kernel} linux-${kernel}-headers broadcom-wl-dkms" install
    else
        ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "linux linux-headers broadcom-wl" install
    fi
}

# Additional packages (airootfs)
make_packages() {
    # インストールするパッケージのリストを読み込み、配列pkglistに代入します。
    installpkglist() {
        set +e
        local _loadfilelist
        local _pkg
        local _file
        local jplist
        local excludefile
        local excludelist
        local _pkglist

        #-- Detect package list to load --#
        # Append the file in the share directory to the file to be read.

        # Package list for Japanese
        jplist="${script_path}/channels/share/packages.${arch}/jp.${arch}"

        # Package list for non-Japanese
        nojplist="${script_path}/channels/share/packages.${arch}/non-jp.${arch}"

        if [[ "${japanese}" = true ]]; then
            _loadfilelist=($(ls "${script_path}"/channels/share/packages.${arch}/*.${arch} | grep -xv "${nojplist}"))
        else
            _loadfilelist=($(ls "${script_path}"/channels/share/packages.${arch}/*.${arch} | grep -xv "${jplist}"))
        fi


        # Add the files for each channel to the list of files to read.

        # Package list for Japanese
        jplist="${script_path}/channels/${channel_name}/packages.${arch}/jp.${arch}"

        # Package list for non-Japanese
        nojplist="${script_path}/channels/${channel_name}/packages.${arch}/non-jp.${arch}"

        if [[ "${japanese}" = true ]]; then
            # If Japanese is enabled, add it to the list of files to read other than non-jp.
            _loadfilelist=(${_loadfilelist[@]} $(ls "${script_path}"/channels/${channel_name}/packages.${arch}/*.${arch} | grep -xv "${nojplist}"))
        else
            # If Japanese is disabled, add it to the list of files to read other than jp.
            _loadfilelist=(${_loadfilelist[@]} $(ls "${script_path}"/channels/${channel_name}/packages.${arch}/*.${arch} | grep -xv ${jplist}))
        fi


        #-- Read package list --#
        # Read the file and remove comments starting with # and add it to the list of packages to install.
        for _file in ${_loadfilelist[@]}; do
            _msg_debug "Loaded package file ${_file}."
            pkglist=( ${pkglist[@]} "$(grep -h -v ^'#' ${_file})" )
        done
        if [[ ${debug} = true ]]; then
            sleep 3
        fi

        # Exclude packages from the share exclusion list
        excludefile="${script_path}/channels/share/packages.${arch}/exclude"
        if [[ -f "${excludefile}" ]]; then
            excludelist=( $(grep -h -v ^'#' "${excludefile}") )

            # 現在のpkglistをコピーする
            _pkglist=(${pkglist[@]})
            unset pkglist
            for _pkg in ${_pkglist[@]}; do
                # もし変数_pkgの値が配列excludelistに含まれていなかったらpkglistに追加する
                if [[ ! $(printf '%s\n' "${excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
                    pkglist=(${pkglist[@]} "${_pkg}")
                fi
            done
        fi

        if [[ -n "${excludelist[@]}" ]]; then
            _msg_debug "The following packages have been removed from the installation list."
            _msg_debug "Excluded packages: ${excludelist[@]}"
        fi

        # Exclude packages from the exclusion list for each channel
        excludefile="${script_path}/channels/${channel_name}/packages.${arch}/exclude"
        if [[ -f "${excludefile}" ]]; then
            excludelist=( $(grep -h -v ^'#' "${excludefile}") )
        
            # 現在のpkglistをコピーする
            _pkglist=(${pkglist[@]})
            unset pkglist
            for _pkg in ${_pkglist[@]}; do
                # もし変数_pkgの値が配列excludelistに含まれていなかったらpkglistに追加する
                if [[ ! $(printf '%s\n' "${excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
                    pkglist=(${pkglist[@]} "${_pkg}")
                fi
            done
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


        #-- Debug code --#
        #for _pkg in ${pkglist[@]}; do
        #    echo -n "${_pkg} "
        #done
        # echo "${pkglist[@]}"


        set -e
    }

    installpkglist

    # _msg_debug "${pkglist[@]}"

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo "# The list of packages that is installed in live cd." > ${work_dir}/packages.list
    echo "#" >> ${work_dir}/packages.list
    echo >> ${work_dir}/packages.list
    for _pkg in ${pkglist[@]}; do
        echo ${_pkg} >> ${work_dir}/packages.list
    done

    # Install packages on airootfs
    ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -p "${pkglist[@]}" install
}

# Customize installation (airootfs)
make_customize_airootfs() {
    # Overwrite airootfs with customize_airootfs.
    local copy_airootfs

    copy_airootfs() {
        local i 
        for i in "${@}"; do
            local _dir="${1%/}"
            if [[ -d "${_dir}" ]]; then
                cp -af "${_dir}"/* "${work_dir}/${arch}/airootfs"
            fi
        done
    }

    copy_airootfs "${script_path}/channels/share/airootfs.any"
    copy_airootfs "${script_path}/channels/share/airootfs.${arch}"
    copy_airootfs "${script_path}/channels/${channel_name}/airootfs.any"
    copy_airootfs "${script_path}/channels/${channel_name}/airootfs.${arch}"

    # Replace /etc/mkinitcpio.conf if Plymouth is enabled.
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-plymouth.conf" "${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf"
    fi

    # Code to use common pacman.conf in archiso.
    # cp "${script_path}/pacman.conf" "${work_dir}/${arch}/airootfs/etc"
    # cp "${build_pacman_conf}" "${work_dir}/${arch}/airootfs/etc"

    # Get the optimal mirror list.
    local mirrorlisturl
    local mirrorlisturl_all
    local mirrorlisturl_jp


    case "${arch}" in
        "x86_64")
            mirrorlisturl_jp='https://www.archlinux.org/mirrorlist/?country=JP'
            mirrorlisturl_all='https://www.archlinux.org/mirrorlist/?country=all'
            ;;
        "i686")
            mirrorlisturl_jp='https://archlinux32.org/mirrorlist/?country=jp'
            mirrorlisturl_all='https://archlinux32.org/mirrorlist/?country=all'
            ;;
    esac

    if [[ "${japanese}" = true ]]; then
        mirrorlisturl="${mirrorlisturl_jp}"
    else
        mirrorlisturl="${mirrorlisturl_all}"
    fi
    curl -o "${work_dir}/${arch}/airootfs/etc/pacman.d/mirrorlist" "${mirrorlisturl}"

    # Add install guide to /root (disabled)
    # lynx -dump -nolist 'https://wiki.archlinux.org/index.php/Installation_Guide?action=render' >> ${work_dir}/${arch}/airootfs/root/install.txt


    # customize_airootfs.sh options
    # -b            : Enable boot splash.
    # -d            : Enable debug mode.
    # -i <inst_dir> : Set install dir
    # -j            : Enable Japanese.
    # -k <kernel>   : Set kernel name.
    # -o <os name>  : Set os name.
    # -p <password> : Set password.
    # -s <shell>    : Set user shell.
    # -t            : Set plymouth theme.
    # -u <username> : Set live user name.
    # -x            : Enable bash debug mode.
    # -r            : Enable rebuild.


    # Generate options of customize_airootfs.sh.
    local addition_options
    local share_options
    addition_options=
    if [[ ${boot_splash} = true ]]; then
        if [[ -z ${theme_name} ]]; then
            addition_options="${addition_options} -b"
        else
            addition_options="${addition_options} -b -t ${theme_name}"
        fi
    fi
    if [[ ${debug} = true ]]; then
        addition_options="${addition_options} -d"
    fi
    if [[ ${bash_debug} = true ]]; then
        addition_options="${addition_options} -x"
    fi
    if [[ ${japanese} = true ]]; then
        addition_options="${addition_options} -j"
    fi
    if [[ ${rebuild} = true ]]; then
        addition_options="${addition_options} -r"
    fi

    share_options="-p '${password}' -k '${kernel}' -u '${username}' -o '${os_name}' -i '${install_dir}' -s '${usershell}' -a '${arch}'"


    # X permission
    if [[ -f ${work_dir}/${arch}/airootfs/root/customize_airootfs.sh ]]; then
    	chmod 755 "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh"
    fi
    if [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh" ]]; then
        chmod 755 "${work_dir}/${arch}/airootfs/root/customize_airootfs.sh"
    fi
    if [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh" ]]; then
        chmod 755 "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh"
    elif [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh" ]]; then
        chmod 755 "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh"
    fi

    # Execute customize_airootfs.sh.
    if [[ -z ${addition_options} ]]; then
        ${mkalteriso} ${mkalteriso_option} \
            -w "${work_dir}/${arch}" \
            -C "${work_dir}/pacman-${arch}.conf" \
            -D "${install_dir}" \
            -r "/root/customize_airootfs.sh ${share_options}" \
            run
        if [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh" ]]; then
            ${mkalteriso} ${mkalteriso_option} \
                -w "${work_dir}/${arch}" \
                -C "${work_dir}/pacman-${arch}.conf" \
                -D "${install_dir}" \
                -r "/root/customize_airootfs_${channel_name}.sh ${share_options}" \
                run
        elif [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh" ]]; then
            ${mkalteriso} ${mkalteriso_option} \
                -w "${work_dir}/${arch}" \
                -C "${work_dir}/pacman-${arch}.conf" \
                -D "${install_dir}" \
                -r "/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh ${share_options}" \
                run
        fi
    else
        ${mkalteriso} ${mkalteriso_option} \
            -w "${work_dir}/${arch}" \
            -C "${work_dir}/pacman-${arch}.conf" \
            -D "${install_dir}" \
            -r "/root/customize_airootfs.sh ${share_options} ${addition_options}" \
            run

        if [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_${channel_name}.sh" ]]; then
            ${mkalteriso} ${mkalteriso_option} \
                -w "${work_dir}/${arch}" \
                -C "${work_dir}/pacman-${arch}.conf" \
                -D "${install_dir}" \
                -r "/root/customize_airootfs_${channel_name}.sh ${share_options} ${addition_options}" \
                run
        elif [[ -f "${work_dir}/${arch}/airootfs/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh" ]]; then
            ${mkalteriso} ${mkalteriso_option} \
                -w "${work_dir}/${arch}" \
                -C "${work_dir}/pacman-${arch}.conf" \
                -D "${install_dir}" \
                -r "/root/customize_airootfs_$(echo ${channel_name} | sed 's/\.[^\.]*$//').sh ${share_options} ${addition_options}" \
                run
        fi
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

    if [[ ! ${kernel} = "core" ]]; then
        ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux-${kernel} -g /boot/archiso.img" run
    else
        ARCHISO_GNUPG_FD=${gpg_key:+17} ${mkalteriso} ${mkalteriso_option} -w "${work_dir}/${arch}" -C "${work_dir}/pacman-${arch}.conf" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' run
    fi

    if [[ "${gpg_key}" ]]; then
      exec 17<&-
    fi
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p "${work_dir}/iso/${install_dir}/boot/${arch}"
    cp "${work_dir}/${arch}/airootfs/boot/archiso.img" "${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img"

    if [[ ! "${kernel}" = "core" ]]; then
        cp "${work_dir}/${arch}/airootfs/boot/vmlinuz-linux-${kernel}" "${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz-linux-${kernel}"
    else
        cp "${work_dir}/${arch}/airootfs/boot/vmlinuz-linux" "${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz"
    fi
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    # In AlterLinux, memtest has been removed.
    # cp "${work_dir}/${arch}/airootfs/boot/memtest86+/memtest.bin" "${work_dir}/iso/${install_dir}/boot/memtest"
    # cp "${work_dir}/${arch}/airootfs/usr/share/licenses/common/GPL2/license.txt" "${work_dir}/iso/${install_dir}/boot/memtest.COPYING"
    cp "${work_dir}/${arch}/airootfs/boot/intel-ucode.img" "${work_dir}/iso/${install_dir}/boot/intel_ucode.img"
    cp "${work_dir}/${arch}/airootfs/usr/share/licenses/intel-ucode/LICENSE" "${work_dir}/iso/${install_dir}/boot/intel_ucode.LICENSE"
    cp "${work_dir}/${arch}/airootfs/boot/amd-ucode.img" "${work_dir}/iso/${install_dir}/boot/amd_ucode.img"
    cp "${work_dir}/${arch}/airootfs/usr/share/licenses/amd-ucode/LICENSE" "${work_dir}/iso/${install_dir}/boot/amd_ucode.LICENSE"
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    if [[ ! ${kernel} = "core" ]]; then
        _uname_r="$(file -b ${work_dir}/${arch}/airootfs/boot/vmlinuz-linux-${kernel} | awk 'f{print;f=0} /version/{f=1}' RS=' ')"
    else
        _uname_r="$(file -b ${work_dir}/${arch}/airootfs/boot/vmlinuz-linux | awk 'f{print;f=0} /version/{f=1}' RS=' ')"
    fi
    mkdir -p "${work_dir}/iso/${install_dir}/boot/syslinux"

    for _cfg in ${script_path}/syslinux/${arch}/*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%INSTALL_DIR%|${install_dir}|g" "${_cfg}" > "${work_dir}/iso/${install_dir}/boot/syslinux/${_cfg##*/}"
    done

    if [[ ${boot_splash} = true ]]; then
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
             "${script_path}/syslinux/${arch}/pxe-plymouth/archiso_pxe-${kernel}.cfg" > "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_pxe.cfg"

        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
             "${script_path}/syslinux/${arch}/sys-plymouth/archiso_sys-${kernel}.cfg" > "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_sys.cfg"
    else
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
             "${script_path}/syslinux/${arch}/pxe/archiso_pxe-${kernel}.cfg" > "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_pxe.cfg"

        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
             "${script_path}/syslinux/${arch}/sys/archiso_sys-${kernel}.cfg" > "${work_dir}/iso/${install_dir}/boot/syslinux/archiso_sys.cfg"
    fi

    if [[ -f "${script_path}/channels/${channel_name}/splash.png" ]]; then
        cp "${script_path}/channels/${channel_name}/splash.png" "${work_dir}/iso/${install_dir}/boot/syslinux"
    else
        cp "${script_path}/syslinux/${arch}/splash.png" "${work_dir}/iso/${install_dir}/boot/syslinux"
    fi
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
    cp "${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi" "${work_dir}/iso/EFI/boot/"
    if [[ "${arch}" = "x86_64" ]]; then
        cp "${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi" "${work_dir}/iso/EFI/boot/bootx64.efi"
        cp "${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" "${work_dir}/iso/EFI/boot/loader.efi"
    fi

    mkdir -p "${work_dir}/iso/loader/entries"
    cp "${script_path}/efiboot/loader/loader.conf" "${work_dir}/iso/loader/"
    cp "${script_path}/efiboot/loader/entries/uefi-shell-x86_64.conf" "${work_dir}/iso/loader/entries/"
    cp "${script_path}/efiboot/loader/entries/uefi-shell-full-x86_64.conf" "${work_dir}/iso/loader/entries/"

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        "${script_path}/efiboot/loader/entries/usb/archiso-x86_64-usb-${kernel}.conf" > "${work_dir}/iso/loader/entries/archiso-x86_64.conf"

    # edk2-shell based UEFI shell
    cp /usr/share/edk2-shell/x64/Shell.efi ${work_dir}/iso/EFI/Shell_x64.efi
    cp /usr/share/edk2-shell/x64/Shell_Full.efi ${work_dir}/iso/EFI/Shell_Full_x64.efi
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {
    mkdir -p "${work_dir}/iso/EFI/archiso"
    truncate -s 64M "${work_dir}/iso/EFI/archiso/efiboot.img"
    mkfs.fat -n ARCHISO_EFI "${work_dir}/iso/EFI/archiso/efiboot.img"

    mkdir -p "${work_dir}/efiboot"
    mount "${work_dir}/iso/EFI/archiso/efiboot.img" "${work_dir}/efiboot"

    mkdir -p "${work_dir}/efiboot/EFI/archiso"

    if [[ ! ${kernel} = "core" ]]; then
        cp "${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz-linux-${kernel}" "${work_dir}/efiboot/EFI/archiso/vmlinuz-linux-${kernel}.efi"
    else
        cp "${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz" "${work_dir}/efiboot/EFI/archiso/vmlinuz.efi"
    fi

    cp "${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img" "${work_dir}/efiboot/EFI/archiso/archiso.img"

    cp "${work_dir}/iso/${install_dir}/boot/intel_ucode.img" "${work_dir}/efiboot/EFI/archiso/intel_ucode.img"
    cp "${work_dir}/iso/${install_dir}/boot/amd_ucode.img" "${work_dir}/efiboot/EFI/archiso/amd_ucode.img"

    mkdir -p "${work_dir}/efiboot/EFI/boot"
    cp "${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi" "${work_dir}/efiboot/EFI/boot/"

    if [[ "${arch}" = "x86_64" ]]; then
        cp "${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi" "${work_dir}/efiboot/EFI/boot/bootx64.efi"
        cp "${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" "${work_dir}/efiboot/EFI/boot/loader.efi"
    fi

    mkdir -p "${work_dir}/efiboot/loader/entries"
    cp "${script_path}/efiboot/loader/loader.conf" "${work_dir}/efiboot/loader/"
    cp "${script_path}/efiboot/loader/entries/uefi-shell-x86_64.conf" "${work_dir}/efiboot/loader/entries/"
    cp "${script_path}/efiboot/loader/entries/uefi-shell-full-x86_64.conf" "${work_dir}/efiboot/loader/entries/"


    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%OS_NAME%|${os_name}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        "${script_path}/efiboot/loader/entries/cd/archiso-x86_64-cd-${kernel}.conf" > "${work_dir}/efiboot/loader/entries/archiso-x86_64.conf"

    cp "${work_dir}/iso/EFI/Shell_x64.efi" "${work_dir}/efiboot/EFI/"
    cp "${work_dir}/iso/EFI/Shell_Full_x64.efi" "${work_dir}/efiboot/EFI/"

    umount -d "${work_dir}/efiboot"
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


# Parse options
options="${@}"
_opt_short="a:bc:dg:hjk:lo:p:t:u:w:x"
_opt_long="arch:,boot-splash,comp-type:,debug,gpgkey:,help,japanese,kernel:,cleaning,out:,password:,comp-opts:,user:,work:,bash-debug,nocolor,noconfirm,nodepend,gitversion,shmkalteriso,msgdebug"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- "${@}")
if [[ ${?} != 0 ]]; then
    exit 1
fi

eval set -- "${OPT}"
unset OPT
unset _opt_short
unset _opt_long


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
        -g | --gpgkey)
            gpg_key="$2"
            shift 2
            ;;
        -h | --help)
            _usage
            exit 0
            ;;
        -j | --japanese)
            japanese=true
            shift 1
            ;;
        -k | --kernel)
            if [[ -n $(cat ${script_path}/system/kernel_list-${arch} | grep -h -v ^'#' | grep -x "${2}") ]]; then
                kernel="${2}"
            else
                _msg_error "Invalid kernel ${2}" "1"
            fi
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
            out_dir="${2}"
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
                cd ${script_path}
                iso_version=${iso_version}-$(git rev-parse --short HEAD)
                cd - > /dev/null 2>&1
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


# Show alteriso version
if [[ -d "${script_path}/.git" ]]; then
    cd  "${script_path}"
    _msg_debug "The version of alteriso is $(git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')."
    cd - > /dev/null 2>&1
fi


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
    set -x
    set -v
    mkalteriso_option="${mkalteriso_option} -x"
fi


# Pacman configuration file used only when building
build_pacman_conf=${script_path}/system/pacman-${arch}.conf

# Set rebuild config file
rebuildfile="${work_dir}/build_options"


# Parse channels
set +eu
if [[ -n "${1}" ]]; then
    channel_name="${1}"

    # Channel list
    # check_channel <channel name>
    check_channel() {
        local channel_list
        local i
        channel_list=()
        for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9 }'); do
            if [[ -n $(ls "${script_path}"/channels/${i}) ]]; then
                if [[ ! ${i} = "share" ]]; then
                    if [[ ! $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                        if [[ ! -d "${script_path}/channels/${i}.add" ]]; then
                            channel_list="${channel_list[@]} ${i}"
                        fi
                    else
                        channel_list="${channel_list[@]} ${i}"
                    fi
                fi
            fi
        done
        for i in ${channel_list[@]}; do
            if [[ $(echo "${i}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                if [[ $(echo ${i} | sed 's/\.[^\.]*$//') = ${1} ]]; then
                    echo -n "true"
                    return 0
                fi
            else
                if [[ ${i} = ${1} ]]; then
                    echo -n "true"
                    return 0
                fi
            fi
        done
        if [[ "${channel_name}" = "rebuild" ]] || [[ "${channel_name}" = "clean" ]]; then
            echo -n "true"
            return 0
        else
            echo -n "false"
            return 1
        fi
    }

    if [[ $(check_channel "${channel_name}") = false ]]; then
        _msg_error "Invalid channel ${channel_name}" "1"
    fi

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
            rm -rf "${work_dir}"
            exit 
    fi

    _msg_debug "channel path is ${script_path}/channels/${channel_name}"
fi

# Check architecture for each channel
if [[ ! "${channel_name}" = "rebuild" ]]; then
    if [[ -z $(cat ${script_path}/channels/${channel_name}/architecture | grep -h -v ^'#' | grep -x "${arch}") ]]; then
        _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"
    fi
fi


# Check the value of a variable that can only be set to true or false.
check_bool() {
    _msg_debug -n "Checking ${1}..."
    case $(eval echo '$'${1}) in
        true | false) : ;;
                *) echo; _msg_error "The variable name ${1} is not of bool type." "1";;
    esac
    echo -e " ok"
}

if [[ "${debug}" =  true ]]; then
    echo
fi
check_bool boot_splash
check_bool debug
check_bool bash_debug
check_bool rebuild
check_bool japanese
check_bool cleaning
check_bool noconfirm
check_bool nodepend
check_bool nocolor
check_bool shmkalteriso
check_bool msgdebug
check_bool customized_username

if [[ "${debug}" =  true ]]; then
    echo
fi



set -eu


prepare_build
show_settings
run_once make_pacman_conf
run_once make_basefs
run_once make_packages
run_once make_customize_airootfs
run_once make_setup_mkinitcpio
run_once make_boot
run_once make_boot_extra
run_once make_syslinux
run_once make_isolinux
run_once make_efi
run_once make_efiboot
run_once make_prepare
run_once make_iso

if [[ ${cleaning} = true ]]; then
    remove_work
fi

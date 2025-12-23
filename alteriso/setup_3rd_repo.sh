#!/usr/bin/env bash

set -Eeuo pipefail

config_path="/etc/pacman.conf"
tmp_dir="$(mktemp -d /tmp/alteriso_setup_3rd_repo.XXXXXXXX)"
keyrings_dir="$tmp_dir/keyrings"
target_repo="all" # all|blackarch|archlinuxcn
log_level="info"  # info|quiet

trap _cleanup EXIT TERM INT

_cleanup() {
    rm -rf "$tmp_dir"
}

_pacman_conf() {
    pacman-conf -c "$config_path" "$@"
}

_pacman_key() {
    pacman-key --config "$config_path" "$@"
}

_pacman() {
    command pacman --config "$config_path" "$@"
}

_get_pacman_repolist() {
    _pacman_conf -l
}

# Check if a repository exists in the pacman configuration
# $1: repository name
_has_repo() {
    _get_pacman_repolist | grep -qx "$1"
}

_pacman_S() {
    _pacman -S --noconfirm --needed "$@"
}

_pacman_U() {
    _pacman -U --noconfirm "$@"
}

_msg_info() {
    [[ "$log_level" == "quiet" ]] && return 0
    echo "$@"
}
_msg_error() {
    echo "$@" >&2
}
_msg_warn() {
    echo "$@" >&2
}

# $1: repository name
# $2: include file path
_repo_config() {
    printf '[%s]\nInclude = %s\n' "$1" "$2"
}

_blackarch_install() {
    if _has_repo "blackarch"; then
        _msg_warn "blackarch repository already exists in pacman configuration."
        return 0
    fi

    _blackarch_install_keyring
    _blackarch_install_pkgs
    _blackarch_apppend_repo

}

_arch4edu_install() {
    if _has_repo "arch4edu"; then
        _msg_warn "arch4edu repository already exists in pacman configuration."
        return 0
    fi

    _arch4edu_install_keyring
    _arch4edu_install_pkgs
    _arch4edu_apppend_repo
}

_blackarch_install_keyring() {
    local _url _version _tarfile="blackarch_keyring-latest.tar.gz"

    # 最新バージョンと対応する .tar.gz の URL を取得
    _version=$(_blackarch_keyring_version) || return 1
    _url=$(_blackarch_keyring_latest_files | grep '.tar.gz$' | head -n1) || true
    [[ -n "$_url" ]] || {
        _msg_error "failed to get latest blackarch keyring url"
        return 1
    }

    _msg_info "Downloading $_url -> $_tarfile (version=$_version)"
    if ! curl -fL --retry 3 -o "$_tarfile" "$_url"; then
        _msg_error "failed to download $_url"
        return 1
    fi

    # $keyrings_dir に展開
    if ! tar xfz "$_tarfile" --strip-components=1 -C "$keyrings_dir"; then
        _msg_error "failed to extract $_tarfile to $keyrings_dir"
        return 1
    fi

    # pacman-keyを更新
    if ! _pacman_key --populate-from "$keyrings_dir" --populate blackarch; then
        _msg_error "failed to populate pacman keyring for blackarch"
        return 1
    fi

    return 0
}

_archlinuxcn_install_keyring() {
    _keyring_src="https://github.com/archlinuxcn/archlinuxcn-keyring/archive/refs/heads/master.zip"
    if ! curl -fL --retry 3 -o "archlinuxcn-keyring-latest.zip" "$_keyring_src"; then
        _msg_error "failed to download $_keyring_src"
        return 1
    fi

    # $tmp_dir/archlinuxcn_keyring に展開
    mkdir -p "$tmp_dir/archlinuxcn_keyring"
    if ! unzip -q "archlinuxcn-keyring-latest.zip" -d "$tmp_dir/archlinuxcn_keyring"; then
        _msg_error "failed to extract archlinuxcn-keyring-latest.zip to $tmp_dir/archlinuxcn_keyring"
        return 1
    fi

    if ! cp -r "$tmp_dir/archlinuxcn_keyring/archlinuxcn-keyring-master/"* "$keyrings_dir/"; then
        _msg_error "failed to copy archlinuxcn-keyring files to $keyrings_dir"
        return 1
    fi

    # pacman-keyを更新
    if ! _pacman_key --populate-from "$keyrings_dir" --populate archlinuxcn; then
        _msg_error "failed to populate pacman keyring for archlinuxcn"
        return 1
    fi

    return 0
}

_arch4edu_install_keyring() {
    local _key_id="7931B6D628C8D3BA"

    _pacman_key --recv-keys "$_key_id"
    _pacman_key --lsign-key "$_key_id"
    _pacman_key --finger "$_key_id"
}

_blackarch_install_pkgs() {
    # Prepare blackarch-mirrorlist
    _blackarch_mirrorlist >"$tmp_dir/blackarch-mirrorlist"

    # Prepare blackarch.conf
    local _conf_file="$tmp_dir/blackarch.conf"
    _pacman_conf >"$_conf_file"
    _repo_config blackarch "$tmp_dir/blackarch-mirrorlist" >>"$_conf_file"

    # Install blackarch-keyring and blackarch-mirrorlist using the temporary config
    local _old_config_path="$config_path"
    config_path="$_conf_file"
    _pacman_S -y blackarch-keyring blackarch-mirrorlist
    config_path="$_old_config_path"
}

_archlinuxcn_install_pkgs() {
    # Prepare archlinuxcn-mirrorlist
    _archlinuxcn_mirrorlist >"$tmp_dir/archlinuxcn-mirrorlist"

    # Prepare archlinuxcn.conf
    local _conf_file="$tmp_dir/archlinuxcn.conf"
    _pacman_conf >"$_conf_file"
    _repo_config archlinuxcn "$tmp_dir/archlinuxcn-mirrorlist" >>"$_conf_file"

    # Install archlinuxcn-keyring using the temporary config
    local _old_config_path="$config_path"
    config_path="$_conf_file"
    _pacman_S -y archlinuxcn-keyring archlinuxcn-mirrorlist-git
    config_path="$_old_config_path"
}

_arch4edu_install_pkgs() {
    # Prepare arch4edu-mirrorlist
    _arch4edu_mirrorlist >"$tmp_dir/arch4edu-mirrorlist"

    # Prepare arch4edu.conf
    local _conf_file="$tmp_dir/arch4edu.conf"
    _pacman_conf >"$_conf_file"
    _repo_config arch4edu "$tmp_dir/arch4edu-mirrorlist" >>"$_conf_file"

    # Install arch4edu-keyring using the temporary config
    local _old_config_path="$config_path"
    config_path="$_conf_file"
    _pacman_S -y arch4edu-keyring arch4edu-mirrorlist
    config_path="$_old_config_path"
}

_blackarch_apppend_repo() {
    _repo_config blackarch "/etc/pacman.d/blackarch-mirrorlist" >>"/etc/pacman.conf"
}

_blackarch_keyring_files() {
    local _url="https://www.blackarch.org/keyring/"

    if ! curl -fsSL "$_url" \
        | awk -F '"' '/<a href="[^"]+"/ {print $2}' \
        | grep -v '/$' \
        | sed "s|^|$_url|"; then
        _msg_error "failed to fetch keyring file list from $_url"
        return 1
    fi
}

_blackarch_keyring_version() {
    local _v
    _v=$(_blackarch_keyring_files \
        | awk -F/ '{print $NF}' \
        | sed -En 's/^blackarch-keyring-([0-9]{8})\.tar\.gz(\.sig)?$/\1/p' \
        | sort | tail -n1) || true
    [[ -n "$_v" ]] || {
        _msg_error "failed to determine blackarch keyring version"
        return 1
    }
    printf '%s\n' "$_v"
}

_archlinuxcn_install() {
    if _has_repo "archlinuxcn"; then
        _msg_warn "archlinuxcn repository already exists in pacman configuration."
        return 0
    fi

    _archlinuxcn_install_keyring
    _archlinuxcn_install_pkgs
    _archlinuxcn_apppend_repo
}

_archlinuxcn_apppend_repo() {
    _repo_config archlinuxcn "/etc/pacman.d/archlinuxcn-mirrorlist" >>"/etc/pacman.conf"
}

_arch4edu_apppend_repo() {
    _repo_config arch4edu "/etc/pacman.d/mirrorlist.arch4edu" >>"/etc/pacman.conf"
}

_blackarch_keyring_latest_files() {
    local _ver _urls
    _ver=$(_blackarch_keyring_version) || return 1
    _urls=$(_blackarch_keyring_files | grep "blackarch-keyring-${_ver}\.tar\.gz") || true
    [[ -n "$_urls" ]] || {
        _msg_error "failed to find keyring files for version $_ver"
        return 1
    }
    printf '%s\n' "$_urls"
}

_blackarch_mirrorlist() {
    curl -fsSL "https://blackarch.org/blackarch-mirrorlist" #| sed 's/#Server/Server/'
}

_archlinuxcn_mirrorlist() {
    curl -fsSL "https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/refs/heads/master/archlinuxcn-mirrorlist" | sed 's/^# Server/Server/'
}

_arch4edu_mirrorlist() {
    curl -fsSL "https://raw.githubusercontent.com/arch4edu/mirrorlist/refs/heads/master/mirrorlist.arch4edu"
}

_init() {
    # Parse flags: -c pacman_config, -r archlinuxcn|blackarch|arch4edu|all, -v, -q
    while getopts ":c:r:vq" opt; do
        case "$opt" in
            c)
                config_path="$OPTARG"
                ;;
            r)
                case "$OPTARG" in
                    blackarch | archlinuxcn | arch4edu | all)
                        target_repo="$OPTARG"
                        ;;
                    *)
                        _msg_error "invalid value for -r: $OPTARG (expected: blackarch|archlinuxcn|all)"
                        exit 1
                        ;;
                esac
                ;;
            v)
                log_level="info"
                ;;
            q)
                log_level="quiet"
                ;;
            ?)
                _msg_error "unknown option: -$OPTARG"
                exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    _pacman_key --init
    mkdir -p "$keyrings_dir"
}

_main() {
    if ((EUID != 0)); then
        _msg_error "This script must be run as root."
        exit 1
    fi

    cd "$tmp_dir" || exit 1
    _init "$@"

    case "$target_repo" in
        blackarch)
            _blackarch_install
            ;;
        archlinuxcn)
            _archlinuxcn_install
            ;;
        arch4edu)
            _arch4edu_install
            ;;
        all)
            _arch4edu_install
            _blackarch_install
            _archlinuxcn_install
            ;;
    esac
    cd "${OLDPWD-.}" || exit 1
}

_main "$@"

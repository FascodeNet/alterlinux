#!/usr/bin/env bash

# 現在のスクリプトのパス
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

# エラーが出た場合はtrueになるので変更禁止
error=false

# パッケージ一覧（初期化）
packages=()

# アーキテクチャ一覧
archs=("x86_64")

# デバッグモード
debug=false

# searchpkg <pkg>
function searchpkg(){
    msg_debug "  In group ..."
    if printf "%s\n" "${group_list[@]}" | grep -x "${1}" >/dev/null; then
        return 0
    fi
    msg_debug "  In official repo (package name)..."
    if [[ -n "$(curl -sL "https://archlinux.org/packages/search/json/?name=${1}" | jq -r '.results[]')" ]]; then
        return 0
    fi
    msg_debug "  In official repo (provides)..."
    if [[ -n "$(curl -sL "https://archlinux.org/packages/search/json/?q=${1}" | jq -r ".results[].provides[]")" ]]; then
        return 0
    fi
    msg_debug "  In YamaD repo ..."
    if [[ -n "$(curl -s https://repo.dyama.net/alter-stable/x86_64/ | grep '\./' | grep "pkg.tar" | sed "s|	||g" | cut -d '"' -f 2 | xargs -If basename f | grep "${1}")" ]]; then
        return 0
    fi
    return 1
}

# ユーザーによって中止された場合に終了
function trap_exit() {
    local status="${?}"
    exit "${status}"
}
trap 'trap_exit' 1 2 3 15

# デバッグモード用関数
msg_debug(){
    if [[ "${debug}" = true ]]; then
        "${script_path}/tools/msg.sh" -s "5" -a "testpkg.sh" -l "Debug" -r "magenta" error "${1}"
    fi
}

# ヘルプ
_help() {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -d | --debug              Enable debug message"
    echo "    -h | --help               This help message"
}


# Parse options
OPTS="dh"
OPTL="debug,help"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${@}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
        -d | --debug)
            debug=true
            shift 1
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --)
            shift 1
            break
            ;;

    esac
done

# パッケージ一覧
msg_debug "Getting package list ..."
for arch in "${archs[@]}"; do
    readarray -O "${#packages[@]}" packages < <("${script_path}/tools/allpkglist.sh" -s -a "${arch}")
done

# ArchLinux公式サイトからパッケージグループの一覧を取得
msg_debug "Getting group list ..."
#group_list=($(curl -s https://archlinux.org/groups/ | grep "/groups/x86_64" | cut -d "/" -f 4))
readarray -t group_list < <(pacman -Sgg | cut -d " " -f 1 | uniq)

# 実行開始
for pkg in "${packages[@]}"; do
    msg_debug "Searching ${pkg} ..."
    if ! searchpkg "${pkg}"; then
        echo "${pkg} is not in the official repository." >&2
        error=true
    fi
done

# エラーが出た場合は異常終了
if [[ "${error}" = true ]]; then
    exit 1
else
    exit 0
fi

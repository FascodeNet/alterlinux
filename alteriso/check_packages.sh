#!/usr/bin/env bash
# LLM Generated: Created by Claude
#
# 生成したプロファイルのパッケージリストが解決できるかを、ISOを焼かずに確かめる。
# 各configについて、variant無しと、そのconfigが提供する各variantを1つずつ試す。

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
alteriso="${ALTERISO:-alteriso}"
configs_dir="${ALTERISO_CONFIGS:-${script_dir}/configs}"
modules_dir="${ALTERISO_MODULES:-${script_dir}/modules}"
bootloaders_dir="${ALTERISO_BOOTLOADERS:-${script_dir}/bootloaders}"
host_arch="$(uname -m)"

work_dir="$(mktemp -d)"
trap 'rm -rf -- "${work_dir}"' EXIT

failed=()
skipped=()

resolve() {
    local config="$1" variant="$2"
    local label="${config}${variant:+ +${variant}}"
    local out="${work_dir}/profile"
    local db="${work_dir}/db"
    local args=(--modules "${modules_dir}" --bootloaders "${bootloaders_dir}")

    rm -rf -- "${out}" "${db}"
    [[ -z "${variant}" ]] || args+=(--variant "${variant}")
    if ! "${alteriso}" profile generate "${configs_dir}/${config}" -o "${out}" "${args[@]}"; then
        failed+=("${label} (generate)")
        return
    fi

    local arch
    arch="$(jq -r '.arch // empty' "${out}/profiledef.json")"
    if [[ -z "${arch}" ]]; then
        failed+=("${label} (no arch in profiledef.json)")
        return
    fi
    if [[ "${arch}" != "${host_arch}" ]]; then
        skipped+=("${label} (${arch} on ${host_arch})")
        return
    fi

    # pacman はターゲットが 0 個だと同期だけして成功するので、空リストは自前で落とす
    local packages=()
    if [[ -f "${out}/packages.${arch}" ]]; then
        readarray -t packages < <(grep -hv '^#' "${out}/packages.${arch}" | grep -v '^[[:space:]]*$')
    fi
    if ((${#packages[@]} == 0)); then
        failed+=("${label} (empty package list)")
        return
    fi

    # 同期と解決を分ける。まとめると、ミラー障害がパッケージの不備と同じ表示になる
    mkdir -p -- "${db}"
    if ! pacman -Sy --config "${out}/pacman.conf" --dbpath "${db}" --noconfirm >/dev/null; then
        failed+=("${label} (repo sync: mirror or network, not the package list)")
        return
    fi
    if ! pacman -Sp --config "${out}/pacman.conf" --dbpath "${db}" --noconfirm \
        "${packages[@]}" >/dev/null; then
        failed+=("${label} (resolve)")
        return
    fi
    echo "ok ${label}" >&2
}

for config_dir in "${configs_dir}"/*/; do
    config="$(basename -- "${config_dir}")"
    resolve "${config}" ""

    # プロセス置換だと variants の失敗が set -e に拾われないので、先に受け取る
    if ! variant_list="$("${alteriso}" profile variants "${configs_dir}/${config}" --modules "${modules_dir}")"; then
        failed+=("${config} (variants)")
        continue
    fi
    while read -r variant _; do
        [[ -n "${variant}" ]] || continue
        resolve "${config}" "${variant}"
    done <<<"${variant_list}"
done

if ((${#skipped[@]} > 0)); then
    printf 'skipped: %s\n' "${skipped[@]}" >&2
fi
if ((${#failed[@]} > 0)); then
    printf 'failed: %s\n' "${failed[@]}" >&2
    exit 1
fi

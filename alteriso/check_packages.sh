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
    arch="$(jq -r '.arch' "${out}/profiledef.json")"
    if [[ "${arch}" != "${host_arch}" ]]; then
        echo "skip ${label}: ${arch} packages cannot be resolved on ${host_arch}" >&2
        return
    fi

    local packages=()
    readarray -t packages < <(grep -hv '^#' "${out}/packages.${arch}")

    mkdir -p -- "${db}"
    if ! pacman -Sp --config "${out}/pacman.conf" --dbpath "${db}" --noconfirm -y \
        "${packages[@]}" >/dev/null; then
        failed+=("${label} (resolve)")
        return
    fi
    echo "ok ${label}" >&2
}

for config_dir in "${configs_dir}"/*/; do
    config="$(basename -- "${config_dir}")"
    resolve "${config}" ""
    while read -r variant _; do
        [[ -n "${variant}" ]] || continue
        resolve "${config}" "${variant}"
    done < <("${alteriso}" profile variants "${configs_dir}/${config}" --modules "${modules_dir}")
done

if ((${#failed[@]} > 0)); then
    printf 'failed: %s\n' "${failed[@]}" >&2
    exit 1
fi

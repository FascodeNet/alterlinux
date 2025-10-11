#!/usr/bin/env bash

set -eEuo pipefail
script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

image_path="${1-""}"
if [[ -z "$image_path" ]]; then
    image_path=$(find "$script_path/out" -type f -name "*.iso" | sort | tail -n 1)
fi

"$script_path/../scripts/run_archiso.sh" -i "$image_path" "$@"

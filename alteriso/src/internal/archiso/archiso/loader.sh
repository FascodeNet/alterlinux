#!/usr/bin/env bash

__alteriso_profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

__alteriso_loadfile() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # shellcheck source=/dev/null
        source "$file"
    fi
}

__alteriso_cleanup() {
    unset __alteriso_profile_dir
}

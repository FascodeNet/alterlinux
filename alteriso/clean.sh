#!/usr/bin/env bash

set -eEuo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Root check
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# Unmount
mount | cut -d ' ' -f 3 | grep "$script_path/work" | sort -r | xargs -r umount -lf || true

# Clean
rm -rf "$script_path/work" "$script_path/out"

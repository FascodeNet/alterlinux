#!/usr/bin/env bash

set -eEuo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Unmount
mount | cut -d ' ' -f 3 | grep "$script_path/work" | sort -r | xargs -r umount -lf || true

# Clean
rm -rf "$script_path/work" "$script_path/out"

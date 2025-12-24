#!/usr/bin/env bash

set -Eeuo pipefail

# Determine script path
script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
profile_dir="${1-"${script_path}/configs/xfce"}"
if [[ -n "${1-""}" ]]; then
    shift 1
fi
work_dir="$script_path/work"

# Build the Go binary
binfile="$(mktemp -u)"
go build -o "$binfile" "$script_path/src"

# Execute the build command
sudo PATH="$(realpath "$script_path/../archiso/"):$(sudo -Hiu root bash -c 'echo "$PATH"')" \
    "$binfile" profile \
    --bootloaders "$script_path/bootloaders/" \
    --modules "$script_path/modules/" \
    build \
    --work "$work_dir" \
    --out "$script_path/out" \
    "$profile_dir" "$@"

# Clean up
"$binfile" clean --workdir "$work_dir"
rm "$binfile"

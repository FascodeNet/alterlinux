#!/usr/bin/env bash

set -Eeuo pipefail

# Determine script path
script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
profile_dir="${1-"${script_path}/configs/xfce"}"
if [[ -n "${1-""}" ]]; then
    shift 1
fi

# Build the Go binary
binfile="$(mktemp -u)"
go build -o "$binfile" "$script_path/src"


# Execute the build command
"$binfile" profile \
    --bootloaders "$script_path/bootloaders/" \
    --modules "$script_path/modules/" \
    generate \
    --out "$script_path/out/$(basename "$profile_dir")" \
    "$profile_dir" "$@"

# Clean up
rm "$binfile"

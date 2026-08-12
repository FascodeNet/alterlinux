#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$@" >"$AYAKA_ARGS"
while (( $# > 0 )); do
    case "$1" in
        --arch) arch=$2; shift 2 ;;
        --repo) repo=$2; shift 2 ;;
        --output) output=$2; shift 2 ;;
        --manifest) manifest=$2; shift 2 ;;
        *) shift ;;
    esac
done
if [[ "${AYAKA_MODE-}" == "failure" ]]; then
    exit 1
fi
mkdir -p "$output"
touch "$output/$repo.db.tar.gz"
touch "$output/$repo.db"
touch "$output.lock" "$manifest.lock"
if [[ "${AYAKA_MODE-}" == "invalid-manifest" ]]; then
    printf '{}\n' >"$manifest"
    exit 0
fi
if [[ "${AYAKA_MODE-}" == "external-database" ]]; then
    printf '{"schema_version":1,"arch":"%s","repository":{"name":"%s","path":"%s","database":"%s"},"install":[]}\n' \
        "$arch" "$repo" "$output" "$AYAKA_EXTERNAL_DATABASE" >"$manifest"
    exit 0
fi
printf '{"schema_version":1,"arch":"%s","repository":{"name":"%s","path":"%s","database":"%s/%s.db"},"install":["aur-package","local-package","base"]}\n' \
    "$arch" "$repo" "$output" "$output" "$repo" >"$manifest"

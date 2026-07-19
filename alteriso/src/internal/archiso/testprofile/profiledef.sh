#!/usr/bin/env bash
# shellcheck disable=SC2034

arch="x86_64"
pacman_conf="/dev/null"

__alteriso_injectable="n"
__alteriso_run_once "alteriso_inject_test"
if [[ "$__alteriso_injectable" != "y" ]]; then
    echo "mkarchiso is not injectable." >&2
    exit 1
else
    echo "mkarchiso is injectable." >&2
    exit 0
fi

#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/src" || exit 1
go run . profile generate --bootloaders ../bootloaders -o ../out "$@"

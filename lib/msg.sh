#!/usr/bin/env bash

msg_debug(){
    echo "DBG: $*" >&2
}

msg_info(){
    echo "INF: $*" >&1
}

msg_err(){
    echo "ERR: $*" >&2
}

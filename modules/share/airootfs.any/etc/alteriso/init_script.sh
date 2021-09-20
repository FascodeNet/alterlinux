#!/usr/bin/env bash
if [ "`cat /proc/cmdline | grep 'rd.live.image'`" ]; then
    if [[ -d "/etc/alteriso/base_init.d/" ]]; then
        for extra_script in "/etc/alteriso/base_init.d/"*; do
            bash -c "${extra_script}"
        done
    else
        systemctl disable livesys.service
        rm -rf /etc/systemd/system/livesys.service
    fi
fi


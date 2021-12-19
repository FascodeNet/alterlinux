#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Set autologin session
mkdir -p "/var/lib/AccountsService/users/"
remove "/var/lib/AccountsService/users/${username}"
cat > "/var/lib/AccountsService/users/${username}" << "EOF"
[User]
Language=
Session=gnome-xorg
XSession=gnome-xorg
Icon=/home/${username}/.face
SystemAccount=false
EOF

# Remove shortcuts
function remove_userfile() {
    remove "/home/${username}/${1#/}"
    remove "/etc/skel/${1#/}"
}
remove_userfile "Desktop/calamares.desktop"
#remove_userfile ".config/autostart/genicon.desktop"

# Optimize for i686
if [[ "${arch}" = "i686" ]]; then
    # shellcheck disable=SC2043
    for _file in "/etc/dconf/db/local.d/01-alter-gnome"; do
        sed -i "s|chromium.desktop|firefox.desktop|g; s|Chromium|FireFox|g; s|chromium|firefox|g" "${_file}"
    done
fi

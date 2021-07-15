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

#!/usr/bin/env bash

mkdir -p ${HOME}/.config/gtk-3.0/
touch ${HOME}/.config/gtk-3.0/bookmarks

source ${HOME}/.config/user-dirs.dirs

cat > "${HOME}/.config/gtk-3.0/bookmarks" << EOF
file://${XDG_DOCUMENTS_DIR}/
file://${XDG_DOWNLOAD_DIR}/
file://${XDG_MUSIC_DIR}/
file://${XDG_PICTURES_DIR}
file://${XDG_TEMPLATES_DIR}
file://${XDG_VIDEOS_DIR}
EOF

rm -f ~/.setup.sh

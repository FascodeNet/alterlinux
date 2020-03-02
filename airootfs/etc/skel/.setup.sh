#!/usr/bin/env bash

# Creating a xdg
LANG=C
xdg-user-dirs-update

HOME="~"
if [[ -f ${HOME}/.config/user-dirs.dirs ]]; then
    source ${HOME}/.config/user-dirs.dirs

    # Add pictures to bookmark
    echo -n "file://" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -n "${XDG_PICTURES_DIR}" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -ne "\n" >> ${HOME}/.config/gtk-3.0/bookmarks

    # Add videos to bookmark
    echo -n "file://" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -n "${XDG_VIDEOS_DIR}" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -ne "\n" >> ${HOME}/.config/gtk-3.0/bookmarks

    # Add music to bookmark
    echo -n "file://" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -n "${XDG_VIDEOS_DIR}" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -ne "\n" >> ${HOME}/.config/gtk-3.0/bookmarks

    # Add downloads to bookmark
    echo -n "file://" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -n "${XDG_DOWNLOAD_DIR}" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -ne "\n" >> ${HOME}/.config/gtk-3.0/bookmarks

    # Add documents to bookmark
    echo -n "file://" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -n "${XDG_DOCUMENTS_DIR}" >> ${HOME}/.config/gtk-3.0/bookmarks
    echo -ne "\n" >> ${HOME}/.config/gtk-3.0/bookmarks
fi
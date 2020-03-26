#!/usr/bin/env bash

echo "file://${HOME}/Documents/\nfile://${HOME}/Downloads/\nfile://${HOME}/Music/\nfile://${HOME}/Pictures/\nfile://${HOME}/Templates/\nfile://${HOME}/Videos/">"${HOME}/.config/gtk-3.0/bookmarks"

rm -f ~/.setup.sh

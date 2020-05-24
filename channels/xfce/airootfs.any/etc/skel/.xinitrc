#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

xset s off

setxkbmap fr

xset +fp /usr/share/fonts/local
xset fp rehash

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# Load config files
[ -f /etc/xprofile ] && source /etc/xprofile
[ -f ~/.xprofile ] && source ~/.xprofile

# Set unzip-iconv
export ZIPINFOOPT=-OCP932
export UNZIPOPT=-OCP932

# No beep
xset -b

# Start xfce4
exec startxfce4
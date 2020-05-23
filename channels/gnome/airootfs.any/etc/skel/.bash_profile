#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.setup.sh ]] && ~/.setup.sh
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
   XDG_SESSION_TYPE=wayland exec dbus-run-session gnome-session
fi
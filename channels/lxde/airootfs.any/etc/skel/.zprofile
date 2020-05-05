#
# ~/.zsh_profile
#

[[ -f ~/.setup.sh ]] && bash ~/.setup.sh
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

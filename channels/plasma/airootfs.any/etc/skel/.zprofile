#
# ~/.zsh_profile
#

[[ -f ~/.setup.sh ]] && ~/.setup.sh
if [[ $(systemctl is-active graphical.target) = "active" ]] && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

#
# ~/.zsh_profile
#

[[ -f /usr/local/bin/alterlinux-user-directory ]] && bash /usr/local/bin/alterlinux-user-directory
if [[ $(systemctl is-active graphical.target) = "active" ]] && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

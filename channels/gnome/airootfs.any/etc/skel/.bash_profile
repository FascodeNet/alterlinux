#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.setup.sh ]] && ~/.setup.sh
if [[ $(systemctl is-active graphical.target) = "active" ]] && [[ -z "${DISPLAY}" && "${XDG_VTNR}" -eq 1 ]]; then
  exec startx
fi
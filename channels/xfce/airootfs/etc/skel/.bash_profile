#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.setup.sh ]] && ~/.setup.sh
[[ -z "${DISPLAY}" && "${XDG_VTNR}" -eq 1 && $(tty) = "/dev/tty1" ]] && exec startx

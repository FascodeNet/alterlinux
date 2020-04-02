#
# ~/.zsh_profile
#

[[ -f ~/.setup.sh ]] && ~/.setup.sh
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

#
# ~/.zsh_profile
#

#if [[ -f ~/.setup.sh ]]; then
#    bash ~/.setup.sh
#    rm ~/.setup.sh
#fi


[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

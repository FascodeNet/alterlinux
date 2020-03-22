#
# ~/.zsh_profile
#
<<DISABLED
if [[ -f ~/.setup.sh ]]; then
    bash ~/.setup.sh
    rm ~/.setup.sh
fi
DISABLED

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

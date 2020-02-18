#
# ~/.bash_profile
#

if [[ -f ~/.setup.sh ]]; then
    bash ~/.setup.sh
    rm ~/.setup.sh
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

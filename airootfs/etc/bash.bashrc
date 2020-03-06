#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $DISPLAY ]] && shopt -s checkwinsize

# PS1='[\u@\h \W]\$ '
PS1='\u@\h:\w\$ ' 

if [[ -f /etc/bash_aliases ]]; then
    source /etc/bash_aliases
fi

export EDITOR=nano

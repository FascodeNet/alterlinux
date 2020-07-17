#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $DISPLAY ]] && shopt -s checkwinsize

# PS1='[\u@\h \W]\$ '
PS1='\u@\h:\w\$ ' 

[[ -f /etc/bash_aliases ]] && source /etc/bash_aliases
[[ -f /etc/bash_functions ]] && source /etc/bash_functions

export EDITOR=nano

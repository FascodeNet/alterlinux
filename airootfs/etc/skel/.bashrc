#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


alias ls='ls --color=auto'

# ArchLinux default
# PS1='[\u@\h \W]\$ '

# No color
# PS1='\u@\h:\w\$ '

# Colored
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#
# ~/.bashrc
#
#
# Yamada Hayao 
# Twitter: @Hayao0819
# Email  : hayao@fascone.net
#
# (c) 2019-2020 Fascode Network.
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Load alias file.
[[ -f ~/.aliases ]] && source ~/.aliases

# Pass the path to ~ / .bin.
[[ -d ~/.bin ]] && export PATH=${PATH}:~/.bin

# ArchLinux default
# PS1='[\u@\h \W]\$ '

# No color
# PS1='\u@\h:\w\$ '

# Colored
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
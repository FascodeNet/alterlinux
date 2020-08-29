#
# ~/.bashrc
#
#
# Yamada Hayao 
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


#-- Archive settings --#
export ZIPINFOOPT=-OCP932
export UNZIPOPT=-OCP932


#-- Load scripts --#
[[ -f ~/.aliases ]] && source ~/.aliases


#-- Pass to the path --#
[[ -d ~/.bin ]] && export PATH=${PATH}:~/.bin


#-- Set prompt --#
if [[ ${TERM} = "linux" ]]; then
    # No color
    PS1='\u@\h:\w\$ '
else
    # ArchLinux default
    # PS1='[\u@\h \W]\$ '

    # No color
    # PS1='\u@\h:\w\$ '

    # Colored
    # PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ']

    # PowerLine-shell
    function _update_ps1() {
        PS1="$(powerline-go -error $?)"
    }

    if [[ "$TERM" != "linux" ]]; then
        PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
    fi
fi
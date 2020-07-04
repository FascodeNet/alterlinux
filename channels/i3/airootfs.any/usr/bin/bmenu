#!/bin/bash

RED='\e[41m'
BLUE='\e[44m'
ORANGE='\e[46m'
NC='\e[0m'

# Service messages section
ERRORMSG="$RED Wrong.$NC"
TRYAGAINMSG="$RED Press any key and try again$NC"
INSTALLINGRNG1MSG="Installing ranger to manage files"
INSTALLINGRNG2MSG="Installing ranger to get a rifle"
INSTALLINGTIMESETMSG="Installing timeset to manage time"
INSTALLINGHTOPMSG="Installing htop to manage tasks"
INSTALLINGBRANDRMSG="Installing brandr to manage display"
INSTALLINGMHWDTUIMSG="Installing mhwd-tui to manage kernels and drivers"
CLIFMNOTINSTMSG="No cli filemanager is installed and pacman seems to be in use"
RIFLENOTINSTMSG="Rifle is not installed and pacman seems to be in use"
TIMESETNOTINSTMSG="Timeset is not installed and pacman seems to be in use"
CLIBROWSNOTINSTMSG="No cli browser installed and pacman seems to be in use"
BRANDRNOTINSTMSG="Brandr is not installed and pacman seems to be in use"
MHWDTUINOTINSTMSG="Mhwd-tui is not installed and pacman seems to be in use"

if [ $(cat /proc/1/comm) = "systemd" ]; then
	systemctl status NetworkManager.service 2>/dev/null | grep -q " active " && netcommand="nmtui"
	systemctl status Netctl.service 2>/dev/null | grep -q " active " && netcommand="sudo wifi-menu"
	systemctl status systemd-networkd 2>/dev/null | grep -q " active " &&  netcommand="wpa_tui"
else
	rc-status | grep -q "NetworkManager" && netcommand="nmtui"
	rc-status | grep -q "Netctl" && netcommand="sudo wifi-menu"
fi

function cli_filemanager {
	if [ -e /usr/bin/ranger ]; then
		ranger
	elif [ -e /usr/bin/mc ]; then
		mc
	else
		echo "$INSTALLINGRNG1MSG"
		if [ - e /var/lib/pacman/db.lck ]; then 
			echo "$CLIFMNOTINSTMSG"
		else 
			sudo pacman -Sy ranger && ranger
		fi
	fi
}

function file_finder {
	if [ -e /usr/bin/rifle ]; then
		rifle $(find -type f | fzf -e --reverse)
	else
		echo "$INSTALLINGRNG2MSG"
		if [ - e /var/lib/pacman/db.lck ]; then 
			echo "$RIFLENOTINSTMSG"
		else 
			sudo pacman -Sy ranger && rifle $(find -type f | fzf -e --reverse)
		fi
	fi
}

function manage_time {
	if [ -e /usr/bin/timeset ]; then
		sudo timeset
	else
		echo "$INSTALLINGTIMESETMSG"
		if [ -e /var/lib/pacman/db.lck ]; then 
			echo "$TIMESETNOTINSTMSG"
		else 
			sudo pacman -Sy timeset && sudo timeset
		fi
	fi
}

function cli_browser {
	if [ -e /usr/bin/elinks ]; then
		elinks
	elif [ -e /usr/bin/w3m ]; then
		w3m
	elif [ -e /usr/bin/links ]; then
		links
	elif [ -e /usr/bin/lynx ]; then
		lynx
	else
		if [ -e /var/lib/pacman/db.lck ]; then 
			echo "$CLIBROWSNOTINSTMSG"
		else 
			sudo pacman -Sy elinks && elinks
		fi
	fi
}

function taskmanager {
	if [ -e /usr/bin/htop ]; then
		htop
	else
		echo "$INSTALLINGHTOPMSG"
		sudo pacman -Sy htop && htop
	fi
}

function display_settings {
	if [ -e /usr/bin/brandr ]; then
		brandr
	else
		echo "$INSTALLINGBRANDRMSG"
		if [ -e /var/lib/pacman/db.lck ]; then 
			echo "$BRANDRNOTINSTMSG"
		else 
			sudo pacman -Sy brandr && brandr
		fi
	fi
}

function hardware_settings {
	if [ -e /usr/bin/mhwd-tui ]; then
		mhwd-tui
	else
		echo "$INSTALLINGMHWDTUIMSG"
		if [ -e /var/lib/pacman/db.lck ]; then 
			echo "$MHWDTUINOTINSTMSG"
		else 
			sudo pacman -Sy mhwd-tui && mhwd-tui
		fi
	fi
}

function init_settings {
if [ $(cat /proc/1/comm) = "systemd" ]; then
	initmenu
else
	initmenu-openrc
fi
}

function main {
    while true; do
    clear
    echo ""
    echo -e "                          ::Main menu:: "
    echo -e " ┌─────────────────────────────────────────────────────────────┐"
    echo -e " │    1   Hardware and drivers         2   Display             │"
    echo -e " │    3   Printers                     4   Appearance          │"
    echo -e " │    5   Package manager              6   Network             │"    
    echo -e " │    7   Sound                        8   Configuration       │"
    echo -e " │    9   Time settings                T   Taskmanager         │"
    echo -e " │    F   File Manager                 B   Browser             │"
    echo -e " │    S   Search                       I   Init-system         │"
    echo -e " └─────────────────────────────────────────────────────────────┘"
    echo -e "          Select an item       -       0   Exit "
    echo ""
    read -s -n1 choix
    case $choix in
        1)
            echo
            hardware_settings
            echo ""
            ;;
        2)
            echo
            display_settings
            echo ""
            ;;
        3)
            echo
            bcups
            echo ""
            ;;
        4)
            echo
            appearance-menu
            echo ""
            ;;
        5)
            echo
            if [[ -e /usr/bin/pacui ]]; then
                pacui
            else
                pacli
            fi
            echo ""
            ;;
        6)
            echo
            $netcommand
            echo ""
            ;;
        7)
            echo
            alsamixer
            echo ""
            ;;
        8)
            echo
            system-settings
            echo ""
            ;;
        9)
            echo
            manage_time
            echo ""
            ;;
        t|T)
            echo
            taskmanager
            echo ""
            ;;
        f|F)
            echo
            cli_filemanager
            echo ""
            ;;
        b|B)
            echo
            cli_browser
            echo ""
            ;;
        s|S)
            echo
            file_finder
            echo ""
            ;;
        i|I)
            echo
            init_settings
            echo ""
            ;;
        0)
            clear && exit
            ;;
        *)
            echo -e "$ERRORMSG$TRYAGAINMSG"
            read -s -n1
	        clear
            ;;
    esac
    done
}

main

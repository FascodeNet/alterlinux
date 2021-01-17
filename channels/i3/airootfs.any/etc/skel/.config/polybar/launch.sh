#!/usr/bin/env bash
# ---------------------------------------------
#  Alter Linux i3wm edition
#  polybar launch script for i3wm
#
#  Watasuke
#  Twitter: @Watasuke102
#  Email  : Watasuke102@gmail.com
#
#  (c) 2019-2021 Fascode Network.
# ---------------------------------------------

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null
	do sleep 1
done

polybar -c ~/.config/polybar/config.ini main &

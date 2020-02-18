#!/usr/bin/env bash

tmp=/tmp/alter-setup

LANG=C

mkdir -p ${tmp}
cd ${tmp}

dialog \
--no-cancel \
--backtitle "Alter Linux Initial setup" \
--radiolist "Which language do yo use?" \
10 40 4 \
1 "English" on \
2 "Japanese" off 2> ${tmp}/lng

selected=$(cat ${tmp}/lng)

case ${selected} in
    1) _lang="en_US.UTF-8" ;;
    2) _lang="ja_JP.UTF-8" ;;
esac

# echo ${_lang}

export LANG=${_lang}
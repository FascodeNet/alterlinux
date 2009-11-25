#!/bin/sh
# This script downloads a entire pacman repo to a dir
# using the locally configured best mirror.
#
# Copyright (c) 2009 Aaron Griffin <aaronmgriffin@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

REPO="$1"
DEST="$2"

REPO_CHANGED=n

if [ -z "$REPO" -o -z "$DEST" ]; then
    echo "usage: $(basename $0) <reponame> <dest-dir>"
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "This script must be run as root (for pacman -Sp)"
    exit 1
fi

[ -d "$DEST" ] || mkdir -p "$DEST"

#update repos
/usr/bin/pacman -Sy

#Ensure we have core/pkgname format, so we don't get crap from other repos
PKGS=$(/usr/bin/pacman -Sl $REPO | cut -d' ' -f1,2 | tr ' ' '/')

if [ -n "$PKGS" ]; then
    baseurl=""
    cachedir="/var/cache/pacman/pkg"
    for url in $(/usr/bin/pacman -Sp $PKGS | grep '://'); do
        baseurl="$(dirname "$url")" #save for later
        pkgname="$(basename "$url")"
        cachedpkg="$cachedir/$pkgname"
        if [ ! -e "$DEST/$pkgname" ]; then
            if [ -e "$cachedpkg" ]; then
                cp -v "$cachedpkg" "$DEST/$pkgname"
                REPO_CHANGED=y
            else
                wget -nv "$url" -O "$DEST/$pkgname"
                REPO_CHANGED=y
            fi
        fi
    done
    if [ "$REPO_CHANGED" = "y" ]; then
        wget -nv "$baseurl/$REPO.db.tar.gz" -O "$DEST/$REPO.db.tar.gz"
    fi
else
    echo "No packages to download... what'd you break?"
    exit 1
fi

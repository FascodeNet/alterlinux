
## Alter Linux - A Japanese-made Arch Linux-derived OS that aims to be usable by anyone

![AlterLogo](../images/logo.png)

[![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=gnu)](../LICENSE)
[![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=arch-linux)](https://www.archlinux.org/)
[![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)](https://git.archlinux.org/archiso.git/tag/?h=v43)
[![Release](https://img.shields.io/github/v/release/SereneTeam/alterlinux?color=blue&include_prereleases&style=for-the-badge)](https://github.com/SereneTeam/alterlinux/releases)

**日本人の方へ**：こちらに日本語版があります。

| [日本語](README_jp.md) | [English](README.md) |
|:-----:|:-----:|

## Overview

Alter Linux is a new OS developed based on Arch Linux.
Combining a sophisticated UI with Xfce4 and a package management tool complete with a GUI, anyone can easily use the latest OS at high speed.
Check the [project board](https://github.com/orgs/SereneTeam/projects/2) for the latest status of AlterLinux.

## Branch
The main branches are: Other branches are temporary or used for specific purposes.
The previously used Japanese branch has been removed.

| [master](https://github.com/SereneTeam/alterlinux/tree/master) | [dev-stable](https://github.com/SereneTeam/alterlinux/tree/dev-stable) | [dev](https://github.com/SereneTeam/alterlinux/tree/dev) |
|:-----:|:-----:|:-----:|
| Most stable. Bug fixes may be delayed. | It is updated regularly. Relatively stable, with the latest features and fixes. | Always updated. There may be many issues left. |

## If you want to give an opinion or impression
If AlterLinux doesn't start, is hard to use, or has any software you want to install by default, feel free to post it to [issues](https://github.com/SereneTeam/alterlinux/issues).
We are soliciting opinions from various users to make AlterLinux better.

##Twitter account
The latest status of Alter Linux is posted on Twitter from time to time. From time to time, we also conduct surveys on future policies.

### Official
The following accounts are official.
- [Alter Linux](https://twitter.com/AlterLinux)
- [SereneLinux Global](https://twitter.com/SereneLinux)
- [SereneLinux JP](https://twitter.com/SereneDevJP)

### Developer
Link to Twitter of main development members.
All comments made on this account are not official SereneTeam statements and are solely for the developer.

<h5 align="center">Development</h5>
<p align="center">
<b><a><a href="https://twitter.com/Hayao0819"><img src="https://avatars1.githubusercontent.com/u/32128205" width="100px" /></a></b>
<b><a><a href="https://twitter.com/Pixel_3a"><img src="https://avatars0.githubusercontent.com/u/48173871" width="100px" /></a></b>
<b><a><a href="https://twitter.com/yangniao23"><img src="https://avatars0.githubusercontent.com/u/47053316" width="100px" /></a></b>
<b><a><a href="https://twitter.com/yamad_linuxer"><img src="https://avatars1.githubusercontent.com/u/45691925" width="100px" /></a></b>
</p>


<h5 align="center">Design</h5>
<p align="center">
<b><a><a href="https://twitter.com/tukutuN_27"><img src="https://0e0.pw/5yuH" width="100px" /></a></b>
</p>

## Repositories and software
To use packages from the repository, you need to add a key.
Execute the following command to add the key.

```bash
curl -s https://山d.com/repo/fascode.pub | sudo pacman-key -a -
sudo pacman-key --lsign-key development@fascode.net
```

### Repositories
GitHub repositories that were used before are no longer used. Currently [this server](https://xn--d-8o2b.com/repo/) is the latest repository.


### Software
Most packages are official packages or published on the AUR, but some are not in either. The source code of such packages and links to PKGBUILD are listed below.
If you need a binary file, access [the AlterLinux repository](https://xn--d-8o2b.com/repo/alter-stable/x86_64/).

Source code | PKGBUILD
--- | ---
 [alterlinux-calamares](https://github.com/SereneTeam/alterlinux-calamares) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/calamares)
[alterlinux-fcitx-conf](https://github.com/SereneTeam/alterlinux-fcitx-conf) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-fcitx-conf)
[alterlinux-keyring](https://github.com/SereneTeam/alterlinux-keyring) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-keyring)
[alterlinux-mirrorlist](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-mirrorlist) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-mirrorlist)
[alterlinux-wallpapers](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-wallpapers) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-wallpapers)
[alterlinux-xfce-conf](https://github.com/SereneTeam/alterlinux-xfce-conf) | [PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-xfce-conf)

## build

The following procedure is for building with the actual machine ArchLinux.

### Preparation

There are two ways to build, using Arch Linux on the actual machine and building on Docker.
The options of `build.sh` are common.

#### Build on real machine
When building with an actual machine, it is necessary to build in an ArchLinux environment.
You need to add a key to use AlterLinux repository. How to add a key is described above.

Install the necessary packages for the build.

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx
```
Then download the source code.

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build.sh
```


#### Build on container
If you build on Docker, please refer to [this procedure](Howtobuild_on_docker.md).

### build.sh options

#### Basic
Please execute as it is.
The default password is `alter`.
Plymouth has been disabled.
Default compression type is `zstd`.


#### Options
 Purpose | Usage
--- | ---
 Enable boot splash | -b
 Change kernel | -k [kernel]
 Change the username | -u [username]
 Change the password | -p [password]
 Japanese | -j
 Change compression method | -c [comp type]
 Set compression options | -t [comp option]
 Specify output destination directory | -o [dir]
 Specify working directory | -w [dir]


#### Channel
Channels switch between packages to install and files to include.
This mechanism allows you to build various versions of AlterLinux.
The supported channels as of March 21, 2020 are:

Name | Purpose
--- | ---
xfce | This is the default channel that uses Xfce4 for the desktop environment and adds various software.
core | It has only a minimal GUI and installer, and after installation it has a minimal ArchLinux. This is an ArchLinux installer.


##### Example

To build under the following conditions:

- Enable Plymouth
- The compression method is `gzip`
- The kernel is `linux-lqx`
- The password is `ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' stable
```

##### About the kernel
The following types of kernels are currently supported: If unspecified, the normal `linux` kernel will be used.
Make sure to include the `foo` part of` linux-foo` in the `-k` option. For example, `linux-lts` contains` lts`.
  
Below are the supported values and kernels.The description of the kernel is from [ArchWiki](https://wiki.archlinux.org/index.php/Kernel).

Name | Feature
--- | ---
ck | linux-ck contains patches to improve system response.
lts |Long term support (LTS) Linux kernel and modules from the core repository.
lqx | Distro kernel alternative built using Debian configuration and ZEN kernel source for desktop multimedia games.
rt | With this patch, almost all of the kernel can be run in real time.
zen | linux-zen is the wisdom of kernel hackers. It is the best Linux kernel for everyday use.


##### About compression type
See the `mksquashfs` help for compression options and more options.
As of February 12, 2019, `mksquashfs` supports the following methods and options.

```
gzip
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 9 (default 9)
    -Xwindow-size <window-size>
    <window-size> should be 8 .. 15 (default 15)
    -Xstrategy strategy1,strategy2,...,strategyN
    Compress using strategy1,strategy2,...,strategyN in turn
    and choose the best compression.
    Available strategies: default, filtered, huffman_only,
    run_length_encoded and fixed
lzma (no options)
lzo
    -Xalgorithm <algorithm>
    Where <algorithm> is one of:
        lzo1x_1
        lzo1x_1_11
        lzo1x_1_12
        lzo1x_1_15
        lzo1x_999 (default)
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 9 (default 8)
    Only applies to lzo1x_999 algorithm
lz4
    -Xhc
    Compress using LZ4 High Compression
xz
    -Xbcj filter1,filter2,...,filterN
    Compress using filter1,filter2,...,filterN in turn
    (in addition to no filter), and choose the best compression.
    Available filters: x86, arm, armthumb, powerpc, sparc, ia64
    -Xdict-size <dict-size>
    Use <dict-size> as the XZ dictionary size.  The dictionary size
    can be specified as a percentage of the block size, or as an
    absolute value.  The dictionary size must be less than or equal
    to the block size and 8192 bytes or larger.  It must also be
    storable in the xz header as either 2^n or as 2^n+2^(n+1).
    Example dict-sizes are 75%, 50%, 37.5%, 25%, or 32K, 16K, 8K
    etc.
zstd
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 22 (default 15)
```

## Documents
- [About packages](packages.md)
- [How to build on docker](Howtobuild_on_docker.md)
- [How to add supporting a new kernel.](Support_a_new_kernel.md)

## If you cannot start
You can disable the boot animation and boot to see the logs.
Boot from the disk and select `Boot Alter Linux without boot splash (x86_64)`.


## About SereneTeam and developers
SereneTeam is a development team for a Linux distribution composed primarily of junior and senior high school students. Almost all are Japanese and there are a total of 24 members.
[SereneLinux](https://serenelinux.com) based on Ubuntu has been developed and released.
Utilizing our know-how, we are working on the development of Alter Linux, which is the first OS in Arch Linux to be developed in Japan.

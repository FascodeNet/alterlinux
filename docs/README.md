
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

| [master](https://github.com/SereneTeam/alterlinux/tree/master) | [dev-stable](https://github.com/SereneTeam/alterlinux/tree/dev-stable) | [dev](https://github.com/SereneTeam/alterlinux/tree/dev) |
|:-----:|:-----:|:-----:|
| Most stable. Bug fixes may be delayed. | It is updated regularly. Relatively stable, with the latest features and fixes. | Always updated. There may be many issues left. |

## Repositories and software

### Repositories
- [SereneTeam/alter-repo](https://github.com/SereneTeam/alter-repo)  
All mirror servers are synchronized with this repository.  


### Software
The source code of the original software included in Alter Linux is below.
The list of packages is [here](https://github.com/SereneTeam/alterlinux/blob/master/packages.x86_64).
The perfect list of all packages is in live image file. 

- [EG-Installer](https://github.com/Hayao0819/EG-Installer)([PKGBUILD](https://github.com/Hayao0819/EG-Installer-PKGBUILD))
- [plymouth-theme-alter](https://github.com/yamad-linuxer/plymouth-theme-alter)([PKGBUILD](https://github.com/Hayao0819/plymouth-theme-alter))
- [lightdm-webkit2-theme-alter](https://github.com/SereneTeam/lightdm-webkit2-theme-alter)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/lightdm-webkit2-theme-alter))
- [calamares](https://gitlab.manjaro.org/applications/calamares)([PKGBUILD](https://gitlab.manjaro.org/packages/extra/calamares))
- [alterlinux-calamares](https://github.com/SereneTeam/alterlinux-calamares)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/calamares))


## build

The following procedure is for building with the actual machine ArchLinux. 

### Preparation

There are two ways to build, using Arch Linux on the actual machine and building on Docker.
The options of `build.sh` are common.

#### Build on real machine
You need to build in ArchLinux environment.  
Add a key to use the AlterLinux repository.

```bash
curl https://山d.com/repo/fascode.pub | sudo pacman-key -a -
sudo pacman-key --lsign-key development@fascode.net
```
Once you have added the key, install the package that will be used for the build.

```bash
sudo pacman -S git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx
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
- Enable Plymouth         : `-b`
- Change compression type : `-c <comp type>`
- Change kernel           : `-k <kernel>`
- Change the password     : `-p <password>`
- Set compression options : `-t <options>`

##### Example

To build under the following conditions:

- Enable Plymouth
- The compression method is `gzip`
- The kernel is `linux-lqx`
- The password is `ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' 
```

##### About the kernel
The following types of kernels are currently supported: If unspecified, the normal `linux` kernel will be used.
Make sure to include the `foo` part of` linux-foo` in the `-k` option. For example, `linux-lts` contains` lts`.
  
Below are the supported values and kernels.The description of the kernel is from [ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB).

- ck   : linux-ck contains patches to improve system response.
- lts  : Long term support (LTS) Linux kernel and modules from the `core` repository.
- lqx  : Distro kernel alternative built using Debian configuration and ZEN kernel source for desktop multimedia games.
- rt   : With this patch, almost all of the kernel can be run in real time.
- zen  : `linux-zen` is the wisdom of kernel hackers. It is the best Linux kernel for everyday use.

##### About compression type
See the `mksquashfs` help for compression options and more options.
As of February 12, 2019, `mksquashfs` supports the following methods and options.

```
gzip (default)
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

## About SereneTeam and developers
SereneTeam is a development team for a Linux distribution composed primarily of junior and senior high school students. Almost all are Japanese and there are a total of 24 members.  
[SereneLinux](https://serenelinux.com) based on Ubuntu has been developed and released.  
Utilizing our know-how, we are working on the development of Alter Linux, which is the first OS in Arch Linux to be developed in Japan.  

###  Twitter　account

#### Official
The following accounts are official.
- [Alter Linux](https://twitter.com/AlterLinux)
- [SereneLinux Global](https://twitter.com/SereneLinux)
- [SereneLinux JP](https://twitter.com/SereneDevJP)

#### Developer
Link to Twitter of main development members.  
All comments made on this account are not official SereneTeam statements and are solely for the developer.  

##### Development
- [Hayao0819](https://twitter.com/Hayao0819)
- [lap1sid](https://twitter.com/Pixel_3a)
- [yamad](https://twitter.com/yamad_linuxer)

##### Design charge
- [tukutun](https://twitter.com/tukutuN_27)

## Build Alter Linux
There are two ways to build, one is to use the actual Arch Linux and the other is to build on Docker.  
Please refer to [This procedure] (DOCKER.md) for how to build with Docker.  
  
When building on a real machine, the OS must be Arch Linux or Alter Linux.
The following explains how to build on a real machine.  
  
TWhen building directly on Arch or Alter, there are several ways to build.  

### Preparation

Get the source code.

```bash
git clone https://github.com/FascodeNet/alterlinux.git
cd alterlinux
```

Add a key to use Alter Linux repository.

```bash
sudo ./keyring.sh --alter-add --arch32-add
```

Install the packages required for build.

```bash
sudo pacman -S --needed git make ninja arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso ninja cmake
```

#### Install the dependencies
Install the packages required for building.  

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso ninja cmake
```

### Use the TUI
You can configure and build using `menuconfig`.  

```bash
make menuconfig
```

### Use the GUI
You can configure and build with the GUI.

```bash
python ./build-wizard.py
```

### Build with options manually

```bash
./build.sh <options> <channel>
``` 

#### option
Run `./build.sh -h` for full options and usage.  

 Purpose | Usage
--- | ---
 Enable boot splash | -b
 Change kernel | -k [kernel]
 Change the username | -u [username]
 Change the password | -p [password]
 Japanese | -l ja
 Change compression method | -c [comp type]
 Set compression options | -t [comp option]
 Specify output destination directory | -o [dir]
 Specify working directory | -w [dir]

##### Note
All options described after the channel name are ignored. Be sure to put the option before the channel name. 

#### An example
Do this to build under the following conditions.

- Enable Plymouth
- The compression method is `gzip`
- The kernel is `linux-lqx`
- The password is `ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' xfce
```

### Notes

#### About channel
Channels switch between packages to install and files to include.  
This mechanism makes it possible to build various versions of Alter Linux.  
The following channels are supported as of August 17, 2020.  
See `./build.sh -h` for a complete list of channels.

Name | Purpose
--- | ---
basic | Base channel for configuring channels
cinnamon | Gorgeous cinnamon desktop with many applications.
gnome | Gnome customized with extension and software for beginner
i3 | using i3, a dynamic tiling window manager inspired by wmii.
lxde | Composed of Lxde and a little software
plasma | Uses KDE and Qt software.
releng | Build ArchLinux as is. Boot splash etc. cannot be used.
xfce | Use Xfce4 for desktop environment.
xfce-pro | Pro Edition with some software added to Xfce and replaced with Compiz
rebuild | Build from the point where it left off using the previous build settings.



#### About the kernel
Both the `i686` architecture and the` x86_64` architecture support the official ArchLinux kernels `linux`,` linux-lts`, and `linux-zen`.  
In addition to the official kernel, `x86_64` also supports the following kernels.  
The description of the kernel is taken from the [ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB).

Name | Characteristic
--- | ---
ck | linux-ck contains patches to improve system responsiveness
lts | Long term support (LTS) Linux kernel and modules in the core repository
lqx | Distro kernel replacement built with Debian settings and ZEN kernel source for desktop multimedia games
rt | This patch will allow you to run almost all of your kernel in real time
zen-letsnote | A `linux-zen` kernel patched to prevent suspend issues with Let's Note (Alter Linux specific)

##### Note
Be sure to put only the `foo` part of` linux-foo` in the `-k` option. For example, in the case of `linux-lts`,` lts` will be entered.  


#### About compression method
See the `mksquashfs` help for compression methods and more options.  
As of February 12, 2019, the methods and options supported by `mksquashfs` are as follows.  

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

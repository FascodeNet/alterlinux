## Build

The following procedure is for building with the actual machine ArchLinux.

### Preparation

There are two ways to build, using Arch Linux on the actual machine and building on Docker.
The options of `build.sh` are common.

```bash
git clone https://github.com/SereneTeam/alterlinux.git alterlinux
cd ./alterlinux/
```
AlterLinux includes a script to easily add keys.

```bash
sudo ./keyring.sh -a
```

#### Build on real machine
When building with an actual machine, it is necessary to build in an ArchLinux environment.  
Install the necessary packages for the build.

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso
```
Then download the source code.

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build.sh
```


#### Build on container
If you build on Docker, please refer to [this procedure](en/DOCKER.md).

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


##### Example

To build under the following conditions:

- Enable Plymouth
- The compression method is `gzip`
- The kernel is `linux-lqx`
- The password is `ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' stable
```


#### Channel
Channels switch between packages to install and files to include.
This mechanism allows you to build various versions of AlterLinux.
The supported channels as of March 21, 2020 are:

Name | Purpose
--- | ---
xfce | This is the default channel that uses Xfce4 for the desktop environment and adds various software.
plasma | This is an edition with Plasma and Qt apps. Currently in development and not stable.


#### About the kernel
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
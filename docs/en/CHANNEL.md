# What is a channel

Channel is an Alter Linux original mechanism that is made so that you can easily switch the files (airootfs) to be included in the image file, the packages to install, the configuration files, etc.  
This mechanism allows you to easily create an AlterOS derivative OS.  
Initially, it was only possible to switch packages, but now the specifications have changed significantly and various changes can be made for each channel.  

The following are channel specifications as of May 13, 2020.  

# Let the script recognize the channel

The conditions for the script to recognize the channel are as follows.

- There is a channel name directory in `channels`
- The directory is not empty

The script will not recognize it if you create an empty directory or create it somewhere else.  
You can check with `./build.sh -h` to see if the script recognized the channel.  
Channels that are not displayed in the Help channel list cannot be used.  

# About channel name

The channel name is basically a directory name in `channels`.  
All the characters that can be used in the directory name can be used in the channel name, but if you use blank characters or double-byte characters, it may not work properly in some environments.  
In addition, it is desirable to keep the channel name within 18 characters because it is handled in the script. (If the number of characters is longer than this, the channel name will not be displayed correctly in the help.)  

If the directory name ends in `.add`, the channel name will be the string before` .add`.  
This is to exclude it from Git management and add your own customized channel.  
Finally, run `./build -h` to check the channel name that can be used as an argument.  

## About duplicate channel names

**Please be careful not to duplicate the channel names with and without `.add`!**  
When the one with .add is duplicated with the one without .add, **the one with .add has priority**.  
Please note that channels without `.add` will be unavailable at all.  
*Also*, <!-- alsoを文頭に使うのは不適切 -->the following special channel names cannot be used.  

# Special channel

There are some special channels. These channels are built into the script and cannot be added or removed.

## share

The `share` channel is a shared channel used regardless of the specified channel.  
`share` has the same structure as other channels, but you cannot specify` share` alone as a channel and build it.  
Add here basic packages and common files that will be installed on all channels.  

## rebuild

This channel is visible in the help, but it is not a directory entity. This channel is embedded in the script.  
This channel is a channel to read the file which saved the build option generated in the working directory and rebuild.  
This channel is embedded in the script.  

# Specifications of each channel

The main directories that make up a channel are `airootfs` and` packages`.  
The `airootfs` directory installs the package and overwrites`/`just before running` mksquashfs`.  
The `packages` directory contains a text file that describes the list of packages to install.  
There are several other files that can be used in some cases.  

## Directories whose names start with airootfs

Please place the file as `/` in each directory. The permissions of all files are inherited as much as possible.  

### airootfs.any

First overwrite the live environment, regardless of the architecture.  

### airootfs.i686 airootfs.x86_64

Airootfs for each architecture.  
`airootfs.x86_64` is used for the` x86_64` architecture, and `airootfs.i686` is used for the` i686`.  

### File duplication priority

For each channel and the file of the `share` channel, the file of each channel has priority.  
*Also*, in the `airootfs.any` and directories for each architecture, the one for each architecture takes precedence.  
The following shows the order in which the `airootfs` are copied. In summary, the left has the least priority and the right has the priority.  

`share/airootfs.any` -> `share/airootfs.<architecture>` -> `<channel_name>/airootfs.any` -> `<channel_name>/airootfs.<architecture>`

## customize_airootfs.sh

If the file `/root/customize_airootfs_ <channel_name>.sh` is placed in the `airootfs` of each channel, the build script will execute the script after `customize_airootfs.sh` is executed.  
（Since `customize_airootfs.sh` is placed by` airootfs.any` of the `share` channel, you can freely overwrite it on each channel.）  
If you want to change the rootfs settings, create this file.  

## Directories whose names start with packages

Placed in this directory, the file name ending in `. <Architecture>` will be loaded as a package list.  
Each line is treated as one package, and lines starting with `#` are treated as comments.  

If the package name or the file name of the package list includes white space characters or double-byte characters, it may not operate properly.  

### Directory type

There is a directory that contains a package list for each architecture. Unlike `airootfs`, there is no shared architecture.  
For example, if the architecture is `x86_64`,` packages.x86_64` will be loaded.

### Special package

There are some packages that should not be described in the package list.See [here](PACKAGE.md) for details.

### Special package list

Special package lists are `jp. <Architecture>` and `non-jp. <Architecture>`.  
When Japanese is enabled by the `-j` option, the script will read` jp. <architecture> `.  
On the contrary, if Japanese is not enabled, the script will use `non-jp. <Architecture>`.  

### Exclusion list

If you have a package in the `share` channel that you really don't want to install, create a file called` exclude` in each channel's `packages` directory and exclude the package by listing the package in it. can.  
For example, if you don't want to install `alterlinux-calamares` that is always installed by` share`, you can add it by adding the package name to `exclude` of that channel and it will not be installed.  
(In that case, delete unnecessary files with customize_airootfs of each channel.)  
The package description method is the same as the package list, one line is treated as one package, and lines beginning with `#` are treated as comments.  

Some packages cannot be excluded.  
Packages that are forced to be installed by the script (`efitools` etc.) will be installed regardless of the exclusion list.  
For example, even if you write `plymouth` in` exclude`, it will be forcibly installed if the `-b` option is enabled.  
If you want to forcefully disable Plymouth, fix `boot_splash` to` false` from `config` of each channel instead of` exclude`.  

`channels/share/packages/exclude` contains a list of packages that the script will force to install.  
This is to log correctly in the working directory and prevent the channel from installing an unusable package.  

*Also*, `exclude` does not remove packages, so you cannot exclude packages that are installed by dependencies.  

### When exclude is applied

`exclude` is applied after all packages have been loaded.  

The order in which the packages are loaded is as follows:  
`share/packages.<architecture>` -> `<channel_name>/packages.<architecture>`  

After that, exclude is loaded in the following order and the packages are excluded.  
`share/packages.<architecture>/exclude` -> `<channel_name>/packages.<architecture>`

## description.txt

This is a text file that describes the channel. It is located in `channels/<channel_name>/description.txt`.  
This file is not mandatory. If this file does not exist, the help will say `This channel does not have a description.txt.`.  

It is recommended to write this file on one line. If you need to write multiple lines, it is better to put 19 single-byte space characters at the beginning of the second and subsequent lines, considering the layout of the text.  

## pacman.conf

Place `channels/<channel_name>/pacman-<architecture>.conf` and use that file at build time. However, since the configuration file after installation will not be replaced, place `/etc/pacman.conf` with` airootfs`.  

## splash.png

By placing `channels/<channel_name>/splash.png`, you can change the background of the SYSLINUX boot loader.
Place a 640x480 image in PNG format.

## config.<architecture>

A script that overwrites existing build settings. Be sure to write it in the shell script syntax.  
The template is placed in the same hierarchy as `build.sh`.  
This configuration file will be overwritten **even by the parameter**, so please describe only the minimum required items. (E.g.<!-- 例えば:exemplī grātiāの略なので --> Plymouth theme name, package name, etc.)  

## warning

Please do not define any local variables in the script. The definition of global variables and the execution of other commands can lead to unexpected behavior.

### Architecture settings and priorities

`channels/<channel_name>/config.any` is loaded, then` channels/<channel_name>/config. <architecture> `is loaded.  

## architecture

A list of architectures available on that channel. `#` Is treated as a comment.

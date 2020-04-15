## What is a channel
A channel is an AlterLinux original mechanism that is made so that you can easily switch the files (airootfs) included in the image file, the packages to install, the configuration files, etc.  
This mechanism allows you to easily create an AlterLinux derivative OS.  
Initially it was only possible to switch packages, but now the specifications have changed significantly, and various changes can be made for each channel.  


The following are channel specifications as of April 14, 2020.  


## Let the script recognize the channel
The conditions for the script to recognize the channel are as follows.  

- There is a channel name directory in `channels`
- The directory is not empty

The script does not recognize you if you create an empty directory or create it elsewhere.  
You can check with `./build.sh -h` to see if the script recognized the channel.  
Channels not displayed in the channel list of the help cannot be used.


## About channel name
The channel name is basically a directory name in `channels`.
All the characters that can be used for the directory name can be used for the channel name, but if you enter a space character or double-byte character, it may not work properly in some environments.  
In addition, it is desirable to keep the channel name within 18 characters because it is handled in the script. (If the number of characters is longer than this, the channel name will not be displayed correctly in the help.)  
  
If the directory name ends in `.add`, the channel name will be the string before .add.
This is to exclude it from Git management and add your own customized channel.
Finally, check the channel name that can be used as an argument by executing `./build -h`.

### About duplicate channel names
**Please DO NOT duplicate the channel name with or without `.add`!**  
Duplicate channel names are not considered in the script and can lead to unexpected behavior.  
In the future, if there are duplicates with and without `.add`, the policy with `.add` will be prioritized.  
Even if you deal with duplicate channel names in the future, the official channel will still be unavailable, so please DO NOT duplicate channel names.



## Specifications of each channel
The main directories that make up the channel are airootfs and packages.  
The `airootfs` directory overwrites `/` just before installing the package and running mksquashfs.
The `packages` directory contains a text file that describes the list of packages to install.  
There are several other files that can be used in some cases.


### airootfs
Place the file in this directory as `/`. The permissions of all files are inherited as much as possible.  

### customize_airootfs.sh
If the file `/root/customize_airootfs_<channel name>.sh` is placed in `airootfs` of each channel, the build script will be executed after `customize_airootfs.sh` is executed.  
If you want to change the rootfs settings, create this file.  


### packages
Placed in this directory, files with names ending in `.x86_64` will be loaded as a package list.  
Each line is treated as one package, and lines starting with `#` are treated as comments.  

If the package name or the file name of the package list includes white space characters or double-byte characters, it may not operate properly.

Some packages should not be included in the package list.See [here](PACKAGE.md) for details.


#### Special package list
As a special package list, there are `jp.x86_64` and `non-jp.x86_64`.  
When Japanese is enabled by the `-j` option, the script will read` jp.x86_64`.  
On the contrary, if Japanese is not enabled, the script will use `non-jp.x86_64`.  


#### Exclusion list
If you have a package on the `share` channel that you really don't want to install, you can exclude it by creating a file called` exclude` in the `packages` directory and listing the package in it.  
For example, if you don't want to install `alterlinux-calamares` that is always installed by` share`, you can add it by adding the package name to `exclude` of that channel.  
(In that case, delete unnecessary files with customize_airootfs of each channel.)  
The package description method is the same as the package list. Each line is treated as one package, and lines beginning with `#` are treated as comments.  
  
Some packages cannot be excluded.  
Packages that are forced to be installed by the script (`efitools` etc.) will be installed regardless of the exclusion list.  
  
`channels / share / packages / exclude` contains a list of packages installed by the above script.  
This is to log accurately in the working directory.  


### description.txt
This is a text file that describes the channel. It is placed in `channels/<channel_name>/description.txt`.  
This file is not mandatory. If this file does not exist, the help will say `This channel does not have a description.txt.`.  

It is recommended to write this file on one line. If you need to write multiple lines, it is better to put 19 half-width spaces at the beginning of the second and subsequent lines, considering the layout of the text.  


### pacman.conf
Place `channels/<channel_name>/pacman.conf` and use that file at build time. However, since the configuration file after installation is not replaced, put `/etc/pacman.conf` in` airootfs`.


### splash.png
By placing `channels / <channel_name> / splash.png`, you can change the background of the SYSLINUX boot loader.Place a 640x480 image in PNG format.  


### config
Placing `channels / <channel_name> / config` allows you to overwrite the existing build configuration. Be sure to write it in the shell script syntax. The template is placed in the same hierarchy as `build.sh`.  
This configuration file will be overwritten ** even the settings by the argument **, so please describe only the minimum required items. (For example, Plymouth theme name and package name)  

## Special channel
There is a special channel, the `share` channel. The `share` channel is a shared channel used regardless of the specified channel.  
Although `share` has the same structure as other channels, it cannot be built by specifying` share` alone as a channel.  
Add here basic packages and common files that will be installed on all channels.  
  
If files are duplicated in `airootfs`, the files in` share` will be overwritten.
For example, if there is a file with the same location in `share` and` xfce`, the file in `xfce` will be used.
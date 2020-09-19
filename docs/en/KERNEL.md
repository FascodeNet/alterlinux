## Support new kernel

This is the procedure to make Alter Linux compatible with the new kernel. Here we explain the procedure to add `linux-fooo`. Replace this character when you do.
You need to add two types of packages to the repository. The kernel body and headers package.


### 1. Create a arch repository

`build.sh` tries to install the kernel using pacman. If you want to add a kernel that is not in the official repository, first create a pacman repository.  
You can easily create a repository using GitHub.  

### 2. Add to kernel list

`kernel-<arch>` is a file written settings about kernel. The syntax is below, and it is analyzes by `build.sh`.  
Line start with `#` treat as comment. One line per one kernel setting.

```bash
#[kernel name]               [kernel filename]               [mkinitcpio profile]
#

core                         vmlinuz-linux                   linux
lts                          vmlinuz-linux-lts               linux-lts
zen                          vmlinuz-linux-zen               linux-zen
```

#### kernel name
This is string specifyed `-k`, a part of `build.sh`. Do not duplicate.  

#### kernel filename
This is name of binary file that create under `/boot`. This is used for Calamares setting, and more.  

#### mkinitcpio profile
This is profile name specified by `-p`, a part of `mkinitcpio`.  

### 3.カーネル用パッケージリストを作成する
Please description kernel package and header package to exclusive package list.  
Check [PACKAGE.md](./PACKAGE.md) for details.  


### 4.プルリクエストを送る
Please create pull request [here](https://github.com/FascodeNet/alterlinux/pulls).


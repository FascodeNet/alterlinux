## Support new kernel

This is the procedure to make Alter Linux compatible with the new kernel. Here we explain the procedure to add `linux-fooo`. Replace this character when you do.
You need to add two types of packages to the repository. The kernel body and headers package.


### 1. Create a arch repository

`build.sh` tries to install the kernel using pacman. If you want to add a kernel that is not in the official repository, first create a pacman repository.  
You can easily create a repository using GitHub.  

### 2. Add to kernel list

Add the kernel name to `kernel_list`. This variable is used to judge whether the value passed to `build.sh` is correct.  
The value to add to the list is the character after `linux-`. In this case it will be `fooo`.  

```bash
echo "fooo" >> ./system/kernel_list
```

### 3. Create the file
You need to create some files for the new kernel. Below is a list of files that need to be created.  
The easiest way is to rename the existing file, copy it, and fix the path to the kernel.  
The file name has been replaced with `fooo`.  

1. syslinux/x86_64/pxe/archiso_pxe-fooo.cfg
2. syslinux/i686/pxe/archiso_pxe-fooo.cfg
3. syslinux/x86_64/pxe-plymouth/archiso-fooo.cfg
4. syslinux/i686/pxe-plymouth/archiso-fooo.cfg
5. syslinux/x86_64/sys/archiso_sys-fooo.cfg
6. syslinux/i686/sys/archiso_sys-fooo.cfg
7. syslinux/x86_64/sys-plymouth/archiso_sys-fooo.cfg
8. syslinux/i686/sys-plymouth/archiso_sys-fooo.cfg
9. efiboot/loader/entries/cd/archiso-x86_64-cd-fooo.conf
10. efiboot/loader/entries/usb/archiso-x86_64-usb-fooo.conf
11. channels/share/airootfs.any/usr/share/calamares/modules/unpackfs/unpackfs-fooo.conf
12. channels/share/airootfs.any/usr/share/calamares/modules/initcpio/initcpio-fooo.conf

These files are installer and boot loader files. Modify the path for each kernel.

### 4.Send pull request
Please post a pull request [here](https://github.com/FascodeNet/alterlinux/pulls).  


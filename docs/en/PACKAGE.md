## Notes on package list

Some packages are added automatically and do not need to be written. The following is a list.

- bash
- base
- haveged
- intel-ucode
- amd-ucode
- mkinitcpio-nfs-utils
- nbd
- efitools

The following packages are installed depending on the situation, and should not be added.

- plymouth theme package specified in config
- plymouth
- linux kernel
- linux headers
- broadcom-wl
- broadcom-wl-dkms
  
Starting May 28, 2021, base-devel is no longer installed by default.  
You need to install it as a package for each channel.  
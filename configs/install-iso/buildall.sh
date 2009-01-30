#!/bin/sh

mkdir release/

#Build grub iso/img's
make clean
make all
mv *.iso *.img release/

# Build isolinux iso's
make clean
make BOOTLOADER=syslinux ftp-iso
rename .iso -isolinux.iso *.iso
mv *.iso release/

# Upload
#cd release
#scp * archlinux.org:public_html/archiso/

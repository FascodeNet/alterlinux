#!/bin/sh

arch="$(uname -m)"

mkdir release/

#Build grub iso/img's
make ARCH=$arch clean
make ARCH=$arch all
mv *.iso *.img release/

# Build isolinux iso's
make ARCH=$arch clean
make ARCH=$arch BOOTLOADER=syslinux all-iso
rename .iso -isolinux.iso *.iso
mv *.iso release/

# Upload
cd release
scp * archlinux.org:public_html/archiso/

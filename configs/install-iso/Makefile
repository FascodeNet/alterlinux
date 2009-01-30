ver=2009.01-beta3
kver=2.6.28-ARCH

WORKDIR=work

ARCH?=i686
BOOTLOADER?=grub-gfx

PWD:=`pwd`
FTPname:=$(PWD)/archlinux-$(ver)-ftp-$(ARCH)
COREname:=$(PWD)/archlinux-$(ver)-core-$(ARCH)

PACKAGES="`cat packages.list` $(BOOTLOADER)"

all: ftp-iso ftp-usb core-iso core-usb
all-iso: ftp-iso core-iso 
all-usb: ftp-usb core-usb 
all-ftp: ftp-iso ftp-usb
all-core: core-iso core-usb

core-usb: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) usb $(WORKDIR) $(COREname).img

core-iso: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) iso $(WORKDIR) $(COREname).iso

ftp-usb: overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) usb $(WORKDIR) $(FTPname).img

ftp-iso: overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) iso $(WORKDIR) $(FTPname).iso

overlay: base-iso
	cp -r overlay $(WORKDIR)/
	sed -i "s|@ARCH@|$(ARCH)|g" "$(WORKDIR)/overlay/etc/pacman.d/mirrorlist"

root-image:
	mkarchiso -p $(PACKAGES) create $(WORKDIR)
	
base-iso: root-image
	mv $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp -r boot-files/* $(WORKDIR)/iso/boot/
	cp isomounts $(WORKDIR)
	sed -i "s|@ARCH@|$(ARCH)|g" "$(WORKDIR)/isomounts"
	
	mkinitcpio -c initcpio-ide -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_ide.img
	mkinitcpio -c initcpio-pata -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_pata.img

core-pkgs: base-iso
	mkdir $(WORKDIR)/core-pkgs/
	./download-repo.sh core "$(WORKDIR)/core-pkgs"

# Bootloaders
grub-gfx:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

grub:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

syslinux:
	cp -r $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/boot/isolinux

clean:
	rm -rf $(WORKDIR) *.img.part1 $(FTPname).img $(FTPname).iso $(COREname).img $(COREname).iso

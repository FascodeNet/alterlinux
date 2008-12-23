ver=2008.12
kver=2.6.27-ARCH

WORKDIR=work

ARCH?=i686
BOOTLOADER?=grub-gfx

PWD:=`pwd`
FTPname:=$(PWD)/archlinux-$(ver)-ftp-$(ARCH)
COREname:=$(PWD)/archlinux-$(ver)-core-$(ARCH)

PACKAGES="`cat packages.list` $(BOOTLOADER)"

all: core-iso core-usb ftp-iso ftp-usb
all-iso: core-iso ftp-iso 
all-usb: core-usb ftp-usb
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

root-image:
	mkarchiso -p $(PACKAGES) create $(WORKDIR)
	
base-iso: root-image
	mv $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp -r boot-files/* $(WORKDIR)/iso/boot/
	cp isomounts $(WORKDIR)
	
	mkinitcpio -c initcpio-ide -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_ide.img
	mkinitcpio -c initcpio-pata -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_pata.img

core-pkgs: base-iso
	mkdir $(WORKDIR)/core-pkgs/
	wget --mirror -P $(WORKDIR)/core-pkgs -nH --cut-dirs=3 ftp://ftp.archlinux.org/core/os/$(ARCH)

# Bootloaders
grub-gfx:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

grub:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

syslinux:
	cp -r $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/boot/isolinux

clean:
	rm -rf $(WORKDIR) *.img.part1 $(FTPname).img $(FTPname).iso $(COREname).img $(COREname).iso

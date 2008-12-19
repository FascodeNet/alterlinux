ver=2008.12
kver=2.6.27-ARCH

#Define outside of 'make' for other arches
ARCH=i686

WORKDIR=work
BOOTLOADER=grub-gfx

PWD=`pwd`
FTPname=$(PWD)/archlinux-$(ver)-ftp-$(ARCH)
COREname=$(PWD)/archlinux-$(ver)-core-$(ARCH)

all: core-iso core-usb ftp-iso ftp-usb
all-iso: core-iso ftp-iso 
all-usb: core-usb ftp-usb

core-usb: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -p $(BOOTLOADER) usb $(WORKDIR) $(FTPname).iso

core-iso: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -p $(BOOTLOADER) iso $(WORKDIR) $(FTPname).iso

ftp-usb: overlay $(BOOTLOADER)
	mkarchiso -p $(BOOTLOADER) usb $(WORKDIR) $(FTPname).img

ftp-iso: overlay $(BOOTLOADER)
	mkarchiso -p $(BOOTLOADER) iso $(WORKDIR) $(FTPname).iso

overlay: base-iso
	cp -r overlay $(WORKDIR)/

root-image:
	mkarchiso -p "`cat packages.list-$(ARCH)` $(BOOTLOADER)" create $(WORKDIR)
	
base-iso: root-image
	mv $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp -r boot-files/* $(WORKDIR)/iso/boot/
	
	mkinitcpio -c initcpio-ide -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso-ide.img
	mkinitcpio -c initcpio-pata -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso-pata.img

grub-gfx:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

grub:
	cp -r $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub

isolinux:
	cp -r $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/boot/isolinux

core-pkgs: base-iso
	mkdir $(WORKDIR)/core-pkgs/
	wget --mirror -P $(WORKDIR)/core-pkgs -nH --cut-dirs=3 ftp://ftp.archlinux.org/core/os/$(ARCH)

clean:
	rm -rf $(WORKDIR) $(FTPname).img $(FTPname).iso $(COREname).img $(COREname).iso

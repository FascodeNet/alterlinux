ver=2009.08
kver=2.6.30-ARCH

WORKDIR=work

ARCH?=`uname -m`
BOOTLOADER?=grub-gfx

PWD:=`pwd`
NETname:=$(PWD)/archlinux-$(ver)-netinstall-$(ARCH)
COREname:=$(PWD)/archlinux-$(ver)-core-$(ARCH)

PACKAGES="$(shell cat packages.$(ARCH)) $(BOOTLOADER)"

all: net-iso net-usb core-iso core-usb
all-iso: net-iso core-iso 
all-usb: net-usb core-usb 
all-net: net-iso net-usb
all-core: core-iso core-usb

core-usb: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) usb $(WORKDIR) $(COREname).img

core-iso: core-pkgs overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) iso $(WORKDIR) $(COREname).iso

net-usb: overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) usb $(WORKDIR) $(NETname).img

net-iso: overlay $(BOOTLOADER)
	mkarchiso -f -p $(BOOTLOADER) iso $(WORKDIR) $(NETname).iso

overlay: base-iso
	cp -r overlay $(WORKDIR)/
	if [ ! -d $(WORKDIR)/overlay/etc/pacman.d ]; then \
	    mkdir -m755 $(WORKDIR)/overlay/etc/pacman.d; \
	fi
	wget -O $(WORKDIR)/overlay/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/$(ARCH)/all/
	sed -i "s/#Server/Server/g" "$(WORKDIR)/overlay/etc/pacman.d/mirrorlist"

root-image:
	mkarchiso -p $(PACKAGES) create $(WORKDIR)
	
base-iso: root-image
	mv $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp -r boot-files/* $(WORKDIR)/iso/boot/
	cp $(WORKDIR)/root-image/usr/share/licenses/common/GPL2/license.txt $(WORKDIR)/iso/boot/memtest86+/memtest.bin-COPYING
	cp isomounts $(WORKDIR)
	sed -i "s|@ARCH@|$(ARCH)|g" "$(WORKDIR)/isomounts"
	
	mkinitcpio -c ./initcpio-ide -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_ide.img
	mkinitcpio -c ./initcpio-pata -b $(WORKDIR)/root-image -k $(kver) -g $(WORKDIR)/iso/boot/archiso_pata.img

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
	rm -rf $(WORKDIR) *.img.part1 $(NETname).img $(NETname).iso $(COREname).img $(COREname).iso

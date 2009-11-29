ver=2009.11
kver=2.6.31-ARCH

WORKDIR=work

ARCH?=$(shell uname -m)
BOOTLOADER?=grub-gfx

PWD=$(shell pwd)
NETname=$(PWD)/archlinux-$(ver)-netinstall-$(ARCH)
COREname=$(PWD)/archlinux-$(ver)-core-$(ARCH)

PACKAGES="$(shell cat packages.$(ARCH)) $(BOOTLOADER)"

all: all-net all-core
all-iso: net-iso core-iso
all-usb: net-usb core-usb
all-net: net-iso net-usb
all-core: core-iso core-usb


# Rules for each type of image
core-iso: $(COREname).iso
$(COREname).iso: core-pkgs base-fs
	mkarchiso -p $(BOOTLOADER) iso $(WORKDIR) $@
core-usb: $(COREname).img
$(COREname).img: core-pkgs base-fs
	mkarchiso -p $(BOOTLOADER) usb $(WORKDIR) $@
net-iso: $(NETname).iso
$(NETname).iso: base-fs
	mkarchiso -p $(BOOTLOADER) iso $(WORKDIR) $@
net-usb: $(NETname).img
$(NETname).img: base-fs 
	mkarchiso -p $(BOOTLOADER) usb $(WORKDIR) $@


# This is the main rule for make the working filesystem.
base-fs: root-image boot-files initcpio overlay iso-mounts $(BOOTLOADER)


# Rules for make the root-image for base filesystem.
root-image: $(WORKDIR)/root-image/.arch-chroot
$(WORKDIR)/root-image/.arch-chroot:
	mkarchiso -p $(PACKAGES) create $(WORKDIR)


# Rule for make /boot
boot-files: root-image
	cp -r $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp $(WORKDIR)/root-image/usr/share/licenses/common/GPL2/license.txt $(WORKDIR)/iso/boot/memtest86+/memtest.bin.COPYING
	cp -r boot-files/* $(WORKDIR)/iso/boot/


# Rules for initcpio images
initcpio: $(WORKDIR)/iso/boot/archiso_ide.img $(WORKDIR)/iso/boot/archiso_pata.img
$(WORKDIR)/iso/boot/archiso_ide.img: initcpio-ide $(WORKDIR)/root-image/.arch-chroot
	mkdir -p $(WORKDIR)/iso/boot
	mkinitcpio -c ./initcpio-ide -b $(WORKDIR)/root-image -k $(kver) -g $@
$(WORKDIR)/iso/boot/archiso_pata.img: initcpio-pata $(WORKDIR)/root-image/.arch-chroot
	mkdir -p $(WORKDIR)/iso/boot
	mkinitcpio -c ./initcpio-pata -b $(WORKDIR)/root-image -k $(kver) -g $@


# overlay filesystem
overlay:
	mkdir -p $(WORKDIR)/overlay/etc/pacman.d
	cp -r overlay $(WORKDIR)/
	wget -O $(WORKDIR)/overlay/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/$(ARCH)/all/
	sed -i "s/#Server/Server/g" $(WORKDIR)/overlay/etc/pacman.d/mirrorlist


# Rule to process isomounts file.
iso-mounts: $(WORKDIR)/isomounts
$(WORKDIR)/isomounts: isomounts root-image
	sed "s|@ARCH@|$(ARCH)|g" isomounts > $@


# Rule for make the [core] repo packages
core-pkgs:
	./download-repo.sh core $(WORKDIR)/core-pkgs


# Rules for bootloaders
grub-gfx: root-image
	mkdir -p $(WORKDIR)/iso/boot/grub
	cp $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub/
grub: root-image
	mkdir -p $(WORKDIR)/iso/boot/grub
	cp $(WORKDIR)/root-image/usr/lib/grub/i386-pc/* $(WORKDIR)/iso/boot/grub/
syslinux: root-image
	mkdir -p $(WORKDIR)/iso/boot/isolinux
	cp $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/boot/isolinux/


# Clean-up all work
clean:
	rm -rf $(WORKDIR) $(NETname).img $(NETname).iso $(COREname).img $(COREname).iso


.PHONY: all all-iso all-usb all-net all-core
.PHONY: net-iso net-usb core-iso core-usb
.PHONY: base-fs
.PHONY: root-image boot-files initcpio overlay iso-mounts
.PHONY: core-pkgs
.PHONY: grub-gfx grub syslinux
.PHONY: clean

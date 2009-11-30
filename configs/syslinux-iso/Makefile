ver=2009.12
kver=2.6.31-ARCH

WORKDIR=work

ARCH?=$(shell uname -m)

PWD=$(shell pwd)
NETname=$(PWD)/archlinux-$(ver)-netinstall-$(ARCH).iso
COREname=$(PWD)/archlinux-$(ver)-core-$(ARCH).iso

PACKAGES="$(shell cat packages.$(ARCH)) $(BOOTLOADER)"

all: net-iso core-iso

# Rules for each type of image
core-iso: $(COREname)
net-iso: $(NETname)

$(COREname): core-pkgs base-fs
	mkarchiso -p syslinux iso $(WORKDIR) $@
$(NETname): base-fs
	mkarchiso -p syslinux iso $(WORKDIR) $@

# This is the main rule for make the working filesystem.
base-fs: root-image boot-files initcpio overlay iso-mounts syslinux


# Rules for make the root-image for base filesystem.
root-image: $(WORKDIR)/root-image/.arch-chroot
$(WORKDIR)/root-image/.arch-chroot:
	mkarchiso -p $(PACKAGES) create $(WORKDIR)

# Rule for make /boot
boot-files: root-image
	cp -r $(WORKDIR)/root-image/boot $(WORKDIR)/iso/
	cp -r boot-files/* $(WORKDIR)/iso/boot/


# Rules for initcpio images
initcpio: $(WORKDIR)/iso/boot/archiso.img
$(WORKDIR)/iso/boot/archiso.img: mkinitcpio.conf root-image
	mkdir -p $(WORKDIR)/iso/boot
	mkinitcpio -c ./mkinitcpio.conf -b $(WORKDIR)/root-image -k $(kver) -g $@


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


# Rules for the bootloader
syslinux: root-image
	mkdir -p $(WORKDIR)/iso/boot/isolinux
	cp $(WORKDIR)/root-image/usr/lib/syslinux/*.c32 $(WORKDIR)/iso/boot/isolinux/
	cp $(WORKDIR)/root-image/usr/lib/syslinux/isolinux.bin $(WORKDIR)/iso/boot/isolinux/


# Clean-up all work
clean:
	rm -rf $(WORKDIR) $(NETname) $(COREname)


.PHONY: all core-iso net-iso
.PHONY: base-fs
.PHONY: root-image boot-files initcpio overlay iso-mounts
.PHONY: core-pkgs
.PHONY: syslinux
.PHONY: clean


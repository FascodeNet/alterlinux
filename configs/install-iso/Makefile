ver=2008.10
kver=2.6.27-ARCH

#Define outside of 'make' for other arches
ARCH=i686

PWD=`pwd`
FTPname=$(PWD)/archlinux-$(ver)-ftp-$(ARCH)
COREname=$(PWD)/archlinux-$(ver)-core-$(ARCH)

all: core-iso core-usb ftp-iso ftp-usb
all-iso: core-iso ftp-iso 
all-usb: core-usb ftp-usb

core-usb: core-pkgs root-image boot-files
	mkarchiso -v -p grub-gfx -t disk image image-dir/ $(COREname).img

core-iso: core-pkgs root-image boot-files
	mkarchiso -v -p grub-gfx image image-dir/ $(FTPname).iso

ftp-usb: root-image boot-files
	mkarchiso -v -p grub-gfx -t disk image image-dir/ $(FTPname).img

ftp-iso: root-image boot-files
	mkarchiso -v -p grub-gfx image image-dir/ $(FTPname).iso

.PHONY: boot-files
boot-files:
	mkdir -p image-dir/boot/
	cp -r boot-files/* image-dir/boot/
	mkinitcpio -c initcpio-ide -b work/ -k $(kver) -g image-dir/boot/archiso-ide.img
	mkinitcpio -c initcpio-pata -b work/ -k $(kver) -g image-dir/boot/archiso-pata.img

root-image:
	chmod 0440 overlay/etc/sudoers
	mkarchiso -v -p "`cat packages.list-$(ARCH)`" install work
	cp -r overlay/* work
	mkdir image-dir/
	mkarchiso -v squash work image-dir/root-image.sqfs

# hacky way to always pull
.PHONY: core-pkgs
core-pkgs:
	wget --mirror -P core-pkgs -nH --cut-dirs=3 ftp://ftp.archlinux.org/core/os/$(ARCH)
	mkdir image/
	mkarchiso -v squash core-pkgs image-dir/core-pkgs.sqfs

clean:
	rm -rf work image

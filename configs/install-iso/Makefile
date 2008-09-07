ver=2008.06
kver=2.6.25-ARCH
carch=i686
FTPname=$(PWD)/archlinux-$(ver)-ftp-$(carch)
COREname=$(PWD)/archlinux-$(ver)-core-$(carch)

all: core-iso core-usb ftp-iso ftp-usb

core-usb: .work-core
	mkinitcpio -c initcpio-ide -b .work-core/install -k $(kver) -g .work-core/img/boot/archlive-ide.img
	mkarchiso -v -t disk -i initcpio-pata img .work-core $(COREname).img

core-iso: .work-core
	mkinitcpio -c initcpio-ide -b .work-core/install -k $(kver) -g .work-core/img/boot/archlive-ide.img
	mkarchiso -v -t iso -i initcpio-pata img .work-core $(COREname).iso


ftp-usb: .work-ftp
	mkinitcpio -c initcpio-ide -b .work-ftp/install -k $(kver) -g .work-ftp/img/boot/archlive-ide.img
	mkarchiso -v -t disk -i initcpio-pata img .work-ftp $(FTPname).img

ftp-iso: .work-ftp
	mkinitcpio -c initcpio-ide -b .work-ftp/install -k $(kver) -g .work-ftp/img/boot/archlive-ide.img
	mkarchiso -v -t iso -i initcpio-pata img .work-ftp $(FTPname).iso

.work-ftp:
	chmod 0440 default-config/etc/sudoers
	mkarchiso -v -P packages.list-$(carch) install .work-ftp
	mkarchiso -v squash .work-ftp

.work-core: addons/core-pkgs
	chmod 0440 default-config/etc/sudoers
	mkarchiso -v -a addons -P packages.list-$(carch) install .work-core
	mkarchiso -v squash .work-core

# hacky way to always pull
.PHONY: addons/core-pkgs
addons/core-pkgs:
	wget --mirror -P addons/core-pkgs -nH --cut-dirs=3 ftp://ftp.archlinux.org/core/os/$(carch)

clean:
	rm -fr .work-ftp .work-core

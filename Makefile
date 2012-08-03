V=1

all:

install: install-program install-hooks install-examples install-doc

install-program:
	install -D -m 755 archiso/mkarchiso $(DESTDIR)/usr/sbin/mkarchiso

install-hooks:
	# hooks/install are needed by mkinitcpio
	install -D -m 644 archiso/hooks/archiso $(DESTDIR)/usr/lib/initcpio/hooks/archiso
	install -D -m 644 archiso/install/archiso $(DESTDIR)/usr/lib/initcpio/install/archiso
	install -D -m 755 archiso/archiso_shutdown $(DESTDIR)/usr/lib/initcpio/archiso_shutdown
	install -D -m 644 archiso/hooks/archiso_shutdown $(DESTDIR)/usr/lib/initcpio/hooks/archiso_shutdown
	install -D -m 644 archiso/install/archiso_shutdown $(DESTDIR)/usr/lib/initcpio/install/archiso_shutdown
	install -D -m 644 archiso/archiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/archiso_pxe_nbd
	install -D -m 644 archiso/hooks/archiso_pxe_common $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_common
	install -D -m 644 archiso/install/archiso_pxe_common $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_common
	install -D -m 644 archiso/hooks/archiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_nbd
	install -D -m 644 archiso/install/archiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_nbd
	install -D -m 644 archiso/hooks/archiso_pxe_http $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_http
	install -D -m 644 archiso/install/archiso_pxe_http $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_http
	install -D -m 644 archiso/hooks/archiso_pxe_nfs $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_nfs
	install -D -m 644 archiso/install/archiso_pxe_nfs $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_nfs
	install -D -m 644 archiso/hooks/archiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/hooks/archiso_loop_mnt
	install -D -m 644 archiso/install/archiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/install/archiso_loop_mnt
	install -D -m 644 archiso/install/archiso_kms $(DESTDIR)/usr/lib/initcpio/install/archiso_kms

install-examples:
	install -d -m 755 $(DESTDIR)/usr/share/archiso/
	cp -r configs $(DESTDIR)/usr/share/archiso/

install-doc:
	install -d -m 755 $(DESTDIR)/usr/share/archiso/
	install -D -m 644 README $(DESTDIR)/usr/share/doc/archiso/README

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkarchiso
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso
	rm -f $(DESTDIR)/usr/lib/initcpio/archiso_shutdown
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_shutdown
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_shutdown
	rm -f $(DESTDIR)/usr/lib/initcpio/archiso_pxe_nbd
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_common
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_common
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_nbd
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_nbd
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_http
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_http
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_pxe_nfs
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_pxe_nfs
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/archiso_loop_mnt
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_loop_mnt
	rm -f $(DESTDIR)/usr/lib/initcpio/install/archiso_kms
	rm -rf $(DESTDIR)/usr/share/archiso/

dist:
	git archive --format=tar --prefix=archiso-$(V)/ v$(V) | gzip -9 > archiso-$(V).tar.gz
	gpg --detach-sign --use-agent archiso-$(V).tar.gz

.PHONY: install install-program install-hooks install-examples install-doc uninstall dist

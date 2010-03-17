all:

install: all
	# install to sbin since script only usable by root
	install -D -m 755 mkarchiso $(DESTDIR)/usr/sbin/mkarchiso
	# testiso can be used by anyone
	install -D -m 755 testiso $(DESTDIR)/usr/bin/testiso
	# hooks/install are needed by mkinitcpio
	install -D -m 644 hooks/archiso $(DESTDIR)/lib/initcpio/hooks/archiso
	install -D -m 644 install/archiso $(DESTDIR)/lib/initcpio/install/archiso
	install -D -m 644 hooks/nbd $(DESTDIR)/lib/initcpio/hooks/nbd
	install -D -m 644 install/nbd $(DESTDIR)/lib/initcpio/install/nbd
	# install docs and examples
	install -d -m 644 $(DESTDIR)/usr/share/archiso/
	cp -r ../configs $(DESTDIR)/usr/share/archiso/configs
	install -D -m 644 ../README $(DESTDIR)/usr/share/doc/archiso/README

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkarchiso
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/lib/initcpio/hooks/archiso
	rm -f $(DESTDIR)/lib/initcpio/install/archiso
	rm -f $(DESTDIR)/lib/initcpio/hooks/nbd
	rm -f $(DESTDIR)/lib/initcpio/install/nbd
	rm -rf $(DESTDIR)/usr/share/archiso/
	rm -rf $(DESTDIR)/usr/share/doc/archiso/

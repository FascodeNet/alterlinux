all:

install: all
	# install to sbin since script only usable by root
	install -D -m 755 mkarchiso $(DESTDIR)/usr/sbin
	install -D -m 755 mkusbimg $(DESTDIR)/usr/sbin
	# testiso can be used by anyone
	install -D -m 755 testiso $(DESTDIR)/usr/bin
	# hooks/install are needed by mkinitcpio
	install -D -m 644 hooks/archiso $(DESTDIR)/lib/initcpio/hooks/
	install -D -m 644 install/archiso $(DESTDIR)/lib/initcpio/install/

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkarchiso
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/lib/initcpio/hooks/archiso
	rm -f $(DESTDIR)/lib/initcpio/install/archiso

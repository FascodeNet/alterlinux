all:

install: all
	# install to sbin since script only usable by root
	install -D -m 755 mkarchiso $(DESTDIR)/usr/sbin/mkarchiso
	# testiso can be used by anyone
	install -D -m 755 testiso $(DESTDIR)/usr/bin/testiso
	# hooks/install are needed by mkinitcpio
	install -D -m 644 hooks/archiso $(DESTDIR)/lib/initcpio/hooks/archiso
	install -D -m 644 hooks/archiso-early $(DESTDIR)/lib/initcpio/hooks/archiso-early
	install -D -m 644 install/archiso $(DESTDIR)/lib/initcpio/install/archiso
	install -D -m 644 install/archiso-early $(DESTDIR)/lib/initcpio/install/archiso-early

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkarchiso
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/lib/initcpio/hooks/archiso
	rm -f $(DESTDIR)/lib/initcpio/install/archiso

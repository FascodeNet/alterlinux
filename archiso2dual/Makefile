all:

install: all
	install -D -m 755 archiso2dual $(DESTDIR)/usr/sbin/archiso2dual
	install -d -m 755 $(DESTDIR)/usr/share/archiso2dual/
	install -D -m 644 isomounts.i686 $(DESTDIR)/usr/share/archiso2dual/isomounts.i686
	install -D -m 644 isomounts.x86_64 $(DESTDIR)/usr/share/archiso2dual/isomounts.x86_64
	install -D -m 644 isomounts.x86_64-i686 $(DESTDIR)/usr/share/archiso2dual/isomounts.x86_64-i686
	install -D -m 644 isolinux.cfg $(DESTDIR)/usr/share/archiso2dual/isolinux.cfg

uninstall:
	rm -f $(DESTDIR)/usr/sbin/archiso2dual
	rm -rf $(DESTDIR)/usr/share/archiso2dual

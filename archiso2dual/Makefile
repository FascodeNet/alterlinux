all:

install: all
	install -D -m 755 archiso2dual $(DESTDIR)/usr/sbin/archiso2dual
	install -d -m 755 $(DESTDIR)/usr/share/archiso2dual/
	install -D -m 644 isomounts $(DESTDIR)/usr/share/archiso2dual/isomounts
	install -D -m 644 syslinux.cfg $(DESTDIR)/usr/share/archiso2dual/syslinux.cfg
	install -D -m 644 removefiles.lst $(DESTDIR)/usr/share/archiso2dual/removefiles.lst

uninstall:
	rm -f $(DESTDIR)/usr/sbin/archiso2dual
	rm -rf $(DESTDIR)/usr/share/archiso2dual

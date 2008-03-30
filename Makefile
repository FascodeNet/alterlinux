all:

install: all
	# install to sbin since script only usable by root
	mkdir -p $(DESTDIR)/usr/sbin
	install -m 755 mkarchiso $(DESTDIR)/usr/sbin
	install -m 755 mkusbimg $(DESTDIR)/usr/sbin
	# testiso can be used by anyone
	mkdir -p $(DESTDIR)/usr/bin
	install -m 755 testiso $(DESTDIR)/usr/bin
	# hooks/install are needed by mkinitcpio
	mkdir -p $(DESTDIR)/lib/initcpio/{hooks,install}
	install -m 644 hooks/{archiso,boot-cd,boot-usb} $(DESTDIR)/lib/initcpio/hooks/
	install -m 644 install/{archiso,boot-cd,boot-usb} $(DESTDIR)/lib/initcpio/install/
	# install default config in a sane location
	mkdir -p $(DESTDIR)/usr/share/archiso
	install -m 644 archiso-mkinitcpio.conf $(DESTDIR)/usr/share/archiso/
	install -m 644 packages.list $(DESTDIR)/usr/share/archiso/
	cp -R default-config $(DESTDIR)/usr/share/archiso/
	# cheating a bit...sudoers HAS to have certain permissions
	chmod 0440 $(DESTDIR)/usr/share/archiso/default-config/etc/sudoers

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkarchiso
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/lib/initcpio/hooks/{archiso,boot-cd,boot-usb}
	rm -f $(DESTDIR)/lib/initcpio/install/{archiso,boot-cd,boot-usb}
	rm -rf $(DESTDIR)/usr/share/archiso

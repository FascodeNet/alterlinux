#
# SPDX-License-Identifier: GPL-3.0-or-later

INSTALL_FILES=$(wildcard archiso/initcpio/install/*)
HOOKS_FILES=$(wildcard archiso/initcpio/hooks/*)
SCRIPT_FILES=$(wildcard archiso/initcpio/script/*)

INSTALL_DIR=$(DESTDIR)/usr/lib/initcpio/install
HOOKS_DIR=$(DESTDIR)/usr/lib/initcpio/hooks
SCRIPT_DIR=$(DESTDIR)/usr/lib/initcpio

DOC_FILES=$(wildcard docs/*) $(wildcard *.rst)

DOC_DIR=$(DESTDIR)/usr/share/doc/archiso


all:

check: lint

lint:
	shellcheck -s bash archiso/mkarchiso \
	                   scripts/run_archiso.sh \
	                   $(INSTALL_FILES) \
	                   $(wildcard configs/*/build.sh) \
	                   $(wildcard configs/*/profiledef.sh) \
	                   configs/releng/airootfs/root/.automated_script.sh \
	                   configs/releng/airootfs/usr/local/bin/choose-mirror
	shellcheck -s dash $(HOOKS_FILES) $(SCRIPT_FILES)

install: install-program install-examples install-doc

install-program:
	install -vDm 755 archiso/mkarchiso -t "$(DESTDIR)/usr/bin/"
	install -vDm 755 scripts/run_archiso.sh "$(DESTDIR)/usr/bin/run_archiso"

install-initcpio:
	install -d $(SCRIPT_DIR) $(HOOKS_DIR) $(INSTALL_DIR)
	install -m 755 -t $(SCRIPT_DIR) $(SCRIPT_FILES)
	install -m 644 -t $(HOOKS_DIR) $(HOOKS_FILES)
	install -m 644 -t $(INSTALL_DIR) $(INSTALL_FILES)

install-examples:
	install -d -m 755 $(DESTDIR)/usr/share/archiso/
	cp -a --no-preserve=ownership configs $(DESTDIR)/usr/share/archiso/

install-doc:
	install -vDm 644 $(DOC_FILES) -t $(DOC_DIR)

.PHONY: check install install-program install-initcpio install-examples install-doc lint

# I'm a make retard, there are probably prettier ways of doing this...

WORKING_DIR=$(PWD)/.work
ISO_NAME=$(PWD)/Archlinux-XFCE4-Live.iso

all: iso 

iso:
	mkarchiso -v -i archiso-mkinitcpio.conf -P packages.list all $(WORKING_DIR) $(ISO_NAME)


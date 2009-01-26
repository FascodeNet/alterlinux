# I'm a make retard, there are probably prettier ways of doing this...

WORKING_DIR=$(PWD)/.work
ISO_NAME=$(PWD)/archlinux-xfce4-live.iso

all: iso 

iso:
	mkarchiso -v -i archiso-mkinitcpio.conf -P packages.list all $(WORKING_DIR) $(ISO_NAME)


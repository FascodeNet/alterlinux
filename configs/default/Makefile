#### Change these settings to modify how this ISO is built
#  The directory that we use for working files
WORKDIR=work
#  A list of packages to install, space separated. Can include groups
PACKAGES="base grub"
# The name of our ISO. Does not specify the architecture!
ISONAME=sample-1.0.0.iso

all:
	mkarchiso -p "$(PACKAGES)" create "$(WORKDIR)"
	
	# Do any editing to $(WORKDIR)/iso/ or $(WORKDIR)/root-image/ here
	# Copy grub files to the ISO dir so we can boot it
	mkdir -p "$(WORKDIR)/iso/boot/grub"
	mv "$(WORKDIR)/root-image/boot" "$(WORKDIR)/iso/"
	cp -r "$(WORKDIR)/root-image/usr/lib/grub/i386-pc/"* "$(WORKDIR)/iso/boot/grub"
	
	# Use our own menu.lst
	cp menu.lst "$(WORKDIR)/iso/boot/grub/"
	
	#Rebuild the mkinitcpio image with the archiso hook
	mkinitcpio -c mkinitcpio.conf -b "$(WORKDIR)/root-image" -k $(kver) -g "$(WORKDIR)/iso/boot/archiso.img"
	
	mkarchiso -p grub iso "$(WORKDIR)" "$(ISONAME)"
	
	# Cleanup our working dir
	rm -rf "$(WORKDIR)"

clean:
	rm -rf "$(WORKDIR)" "$(ISONAME)"

mkdir -p isolinux-test/boot
cp -r boot-files/* isolinux-test/boot/
cp /usr/lib/syslinux/isolinux.bin isolinux-test/boot/isolinux/
cp /usr/lib/syslinux/*.c32 isolinux-test/boot/isolinux/
mkisofs -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -r -l -uid 0 -gid 0 -udf -allow-limited-size -iso-level 3 -input-charset utf-8 -boot-load-size 4 -no-emul-boot -boot-info-table -o isolinux-test.iso isolinux-test && qemu-kvm -cdrom isolinux-test.iso

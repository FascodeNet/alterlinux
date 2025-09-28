==============================================
Transfer ISO to target medium (configs/releng)
==============================================

ISO images names consist of: ``archlinux-YYYY.MM.DD-x86_64.iso``.

Where: ``YYYY`` is the year, ``MM`` the month and ``DD`` the day.

.. contents::

Burn to an optical disc
=======================

  .. note::
     All ISO images are BIOS and UEFI bootable via "El Torito" in no-emulation mode.

Burn the ISO using your favorite disc burning program.

For example:

.. code:: sh

   xorriso -as cdrecord -v -sao dev=/dev/sr0 archlinux-YYYY.MM.DD-x86_64.iso

Write to an USB flash drive / memory card / hard disk drive / solid state drive / etc.
======================================================================================

  .. tip::
     See https://wiki.archlinux.org/title/USB_flash_installation_medium for more detailed instructions.

Nomeclature:

``<DEV-TARGET>``
  Device node of the drive where ISO contents should be copied (example: ``/dev/sdx``).
``<DEV-TARGET-N>``
  Device node of the partition on ``<DEV-TARGET>`` (example: ``/dev/sdx1``).
``<FS-LABEL>``
  Represents the file system label of the ``archlinux-YYYY.MM.DD-x86_64.iso`` (example: ``ARCH_201703``).

ISOHYBRID (BIOS and UEFI)
-------------------------

  .. note::
     This method is the most easily, quick and dirty, but is the most limited if you want to use your target medium
     for other purposes. If using this does not work, use the `File system transposition (UEFI only)`_ method instead.

Directly write the ISO file to the target medium:

.. code:: sh

   dd bs=4M if=archlinux-YYYY.MM.DD-x86_64.iso of=<DEV-TARGET> conv=fsync oflag=direct status=progress

File system transposition (UEFI only)
--------------------------------

This method extracts the contents of the ISO onto a prepared UEFI-bootable volume.

If your drive is already partitioned and formatted, skip to the "Mount the target file system" step.

  .. note::
     Using MBR with one FAT formatted active partition is the most compatible method.

1. Partition the drive with *fdisk*.

   .. code:: sh

      fdisk <DEV-TARGET>

   1) Create a new MBR partition table with command ``o``.

     .. warning::
        This will destroy all data on the drive.

   2) Create a new primary partition with command ``n`` and set its type code to ``0c`` with command ``t``.

   3) Mark the partition as bootable with the ``a`` command.

   4) Write the changes and exit with ``w``.

2. Format the newly created partition to FAT32

   .. code:: sh

      mkfs.fat -F 32 /dev/disk/by-id/<TARGET-DEVICE>-part1

3. Mount the target file system

   .. code:: sh

      mount <DEV-TARGET-N> /mnt

4. Extract the ISO image on the target file system.

   .. code:: sh

      bsdtar -x --exclude=boot/syslinux/ -f archlinux-YYYY.MM.DD-x86_64.iso -C /mnt

5. Unmount the target file system.

   .. code:: sh

      umount /mnt

Manual formatting (BIOS only)
-----------------------------

  .. note::
     These steps are the general workflow, you can skip some of them, using another file system if your boot loader
     supports it, installing to another directory than ``arch/`` or using more than one partition. Just ensure that
     main boot parameters  (``archisolabel=`` and ``archisobasedir=``) are set correctly according to your setup.

     Using here a MBR partition mode as example, but GPT should also work if the machine firmware is not broken. Just
     ensure that partition is set with attribute ``2: legacy BIOS bootable`` and use ``gptmbr.bin`` instead of
     ``mbr.bin`` for syslinux.

1) Create one partition entry in MBR and mark it as "active" (bootable).

     .. note::
        Type ``b`` for FAT32, ``83`` for EXTFS or ``7`` for NTFS.

   .. code:: sh

      fdisk <DEV-TARGET>

2) Create a FAT32, EXTFS or NTFS file system on such partition and setup a label.

     .. note::
        COW is not supported on NTFS.

   .. code:: sh

      mkfs.fat -F 32 -n <FS-LABEL> <DEV-TARGET-N>
      mkfs.ext4 -L <FS-LABEL> <DEV-TARGET-N>
      mkfs.ntfs -L <FS-LABEL> <DEV-TARGET-N>

3) Mount the target file system.

   .. code:: sh

      mount <DEV-TARGET-N> /mnt

4) Extract the ISO image on the target file system.

   .. code:: sh

      bsdtar -x --exclude=boot/grub/ --exclude=EFI/ -f archlinux-YYYY.MM.DD-x86_64.iso -C /mnt

5) Install the syslinux boot loader on the target file system.

   .. code:: sh

      extlinux -i /mnt/boot/syslinux

6) Unmount the target file system.

   .. code:: sh

      umount /mnt

7) Install syslinux MBR boot code on the target drive.

   .. code:: sh

      dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/bios/mbr.bin of=<DEV-TARGET>


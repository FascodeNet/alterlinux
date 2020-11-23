=======
profile
=======

An archiso profile consists of several configuration files and a directory for files to be added to the resulting image.

  .. code:: bash

    profile
    |- airootfs/
    |- efiboot/
    |- isolinux/
    |- syslinux/
    |- packages.arch
    |- pacman.conf
    \- profiledef.sh

The required files and directories are explained in the following sections.

profiledef.sh
=============

This file describes several attributes of the resulting image and is a place for customization to the general behavior
of the image.

The image file is constructed from some of the variables in **profiledef.sh**: `<iso_name>-<iso_version>-<arch>.iso`
(e.g. `archlinux-202010-x86_64.iso`).

* `iso_name`: The first part of the name of the resulting image (defaults to `mkarchiso`)
* `iso_label`: The ISO's volume label (defaults to `MKARCHISO`)
* `iso_publisher`: A free-form string that states the publisher of the resulting image (defaults to `mkarchiso`)
* `iso_application`: A free-form string that states the application (i.e. its use-case) of the resulting image (defaults
  to `mkarchiso iso`)
* `iso_version`: A string that states the version of the resulting image (defaults to `""`)
* `install_dir`: A string (maximum eight characters long, which **must** consist of `[a-z0-9]`) that states the
  directory on the resulting image into which all files will be installed (defaults to `mkarchiso`)
* `bootmodes`: A list of strings, that state the supported boot modes of the resulting image. Only the following are
  understood:
  - `bios.syslinux.mbr`: Syslinux for x86 BIOS booting from a disk
  - `bios.syslinux.eltorito`: Syslinux for x86 BIOS booting from an optical disc
  - `uefi-x64.systemd-boot.esp`: Systemd-boot for x86_64 UEFI booting from a disk
  - `uefi-x64.systemd-boot.eltorito`: Systemd-boot for x86_64 UEFI booting from an optical disc
* `arch`: The architecture (e.g. `x86_64`) to build the image for. This is also used to resolve the name of the packages
  file (e.g. `packages.x86_64`)
* `pacman_conf`: The `pacman.conf` to use to install packages to the work directory when creating the image (defaults to
  the host's `/etc/pacman.conf`)
* `airootfs_image_type`: The image type to create. The following options are understood (defaults to `squashfs`):
  - `squashfs`: Create a squashfs image directly from the airootfs work directory
  - `ext4+squashfs`: Create an ext4 partition, copy the airootfs work directory to it and create a squashfs image from it
* `airootfs_image_tool_options`: An array of options to pass to the tool to create the airootfs image. Currently only
  `mksquashfs` is supported - see `mksquashfs --help` for all possible options (defaults to `('-comp' 'xz')`).

packages.arch
=============

All packages to be installed into the environment of the image have to be listed in an architecture specific file (e.g.
`packages.x86_64`), which resides top-level in the profile.

Packages have to be listed one per line. Lines starting with a `#` and blank lines are ignored.

  .. note::

    The **mkinitcpio** and **mkinitcpio-archiso** packages are mandatory (see `#30
    <https://gitlab.archlinux.org/archlinux/archiso/-/issues/30>`_).

pacman.conf
===========

A configuration for pacman is required per profile.

Some configuration options will not be used or will be modified:

* `CacheDir`: the profile's option is **only** used if it is not the default (i.e. `/var/cache/pacman/pkg`) and if it is
  not the same as the system's option. In all other cases the system's pacman cache is used.
* `HookDir`: it is **always** set to the `/etc/pacman.d/hooks` directory in the work directory's airootfs to allow
  modification via the profile and ensure interoparability with hosts using dracut (see `#73
  <https://gitlab.archlinux.org/archlinux/archiso/-/issues/73>`_)
* `RootDir`: it is **always** removed, as setting it explicitely otherwise refers to the host's root filesystem (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)
* `LogFile`: it is **always** removed, as setting it explicitely otherwise refers to the host's pacman log file (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)
* `DBPath`: it is **always** removed, as setting it explicitely otherwise refers to the host's pacman database (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)

airootfs
========

This - optional - directory may contain files and directories that will be copied to the work directory of the resulting
image's root filesystem.
The files are copied before packages are being installed to work directory location.
Ownership of files and directories from the profile's `airootfs` directory are not preserved (permissions are currently
the same as in the profile's `airootfs` - see `#61 <https://gitlab.archlinux.org/archlinux/archiso/-/issues/73>`_).

With this overlay structure it is possible to e.g. create users and set passwords for them, by providing
`airootfs/etc/passwd`, `airootfs/etc/shadow`, `airootfs/etc/gshadow` (see `man 5 passwd`, `man 5 shadow` and `man 5
gshadow` respectively).
If user home directories exist in the profile's `airootfs`, their ownership and (and top-level) permissions will be
altered according to the provided information in the password file.

Boot loader configuration
=========================

A profile may contain configuration for several boot loaders. These reside in specific top-level directories, which are
explained in the following subsections.

The following *custom template identifiers* are understood and will be replaced according to the assignments of the
respective variables in **profiledef.sh**:

* `%ARCHISO_LABEL%`: Set this using the `iso_label` variable in **profiledef.sh**
* `%INSTALL_DIR%`: Set this using the `iso_label` variable in **profiledef.sh**
* `%ARCH%`: Set this using the `arch` variable in **profiledef.sh**


efiboot
-------

This directory is mandatory when the `uefi-x64.systemd-boot.esp` or `uefi-x64.systemd-boot.eltorito` bootmodes are
selected in **profiledef.sh**. It contains configuration for `systemd-boot
<https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/>`_.

  .. note::

    The directory is a top-level representation of the systemd-boot configuration directories and files found in the
    root of an EFI system partition.

The *custom template identifiers* are **only** understood in the boot loader entry `.conf` files (i.e. **not** in
`loader.conf`).

isolinux
--------

This directory is mandatory when the `bios.syslinux.eltorito` bootmode is selected in **profiledef.sh**.
It contains configuration for `isolinux <https://wiki.syslinux.org/wiki/index.php?title=ISOLINUX>`_ used in the resuling
image.

The *custom template identifiers* are understood in all `.cfg` files in this directory.

syslinux
--------

This directory is mandatory when the `bios.syslinux.mbr` or the `bios.syslinux.eltorito` bootmodes are selected in
**profiledef.sh**.
It contains configuration files for `syslinux <https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX>`_ or `pxelinux
<https://wiki.syslinux.org/wiki/index.php?title=PXELINUX>`_ used in the resuling image.

The *custom template identifiers* are understood in all `.cfg` files in this directory.

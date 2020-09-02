=======
archiso
=======

The archiso project features scripts and configuration templates to build installation media (*.iso* images) for BIOS
and UEFI based systems on the x86_64 architecture.
Currently creating the images is only supported on Arch Linux.

Requirements
============

The following packages need to be installed to be able to create an image with the included scripts:

* arch-install-scripts
* dosfstools
* e2fsprogs
* libisoburn
* mtools
* squashfs-tools

For running the images in a virtualized test environment the following packages are required:

* edk2-ovmf
* qemu

For linting the shell scripts the following package is required:

* shellcheck

Profiles
========

Archiso comes with two profiles: **baseline** and **releng**. While both can serve as starting points for creating
custom live media, **releng** is used to create the monthly installation medium.
They can be found below `configs/baseline/ <configs/baseline/>`_  and `configs/releng/ <configs/releng/>`_
(respectively). Both profiles are defined by files to be placed into overlays (e.g. *airootfs* -> *the image's /*).

Create images
=============

Usually the archiso tools are installed as a package. However, it is also possible to clone this repository and create
images without installing archiso system-wide.

As filesystems are created and various mount actions have to be done when creating an image, **root** is required to run
the scripts.

When archiso is installed system-wide and the modification of a profile is desired, it is necessary to copy it to a
writeable location, as */usr/share/archiso* is tracked by the package manager and only writeable by root (changes will
be lost on update).

The examples below will assume an unmodified profile in a system location (unless noted otherwise).

It is advised to consult the help output of **mkarchiso**:

  .. code:: bash

    mkarchiso -h

Create images with packaged archiso
-----------------------------------

  .. code:: bash

    mkarchiso -w path/to/work_dir -o path/to/out_dir path/to/profile

Create images with local clone
------------------------------

Clone this repository and run:

  .. code:: bash

    ./archiso/mkarchiso -w path/to/work_dir -o path/to/out_dir path/to/profile

Testing
=======

The convenience script **run_archiso** is provided to boot into the medium using qemu.
It is advised to consult its help output:

  .. code:: bash

    run_archiso -h

Run the following to boot the iso using BIOS:

  .. code:: bash

    run_archiso -i path/to/an/arch.iso

Run the following to boot the iso using UEFI:

  .. code:: bash

    run_archiso -u -i path/to/an/arch.iso

The script can of course also be executed from this repository:


  .. code:: bash

    ./scripts/run_archiso.sh -i path/to/an/arch.iso

Installation
============

To install archiso system-wide use the included **Makefile**:

  .. code:: bash

    make install

Optionally install archiso's mkinitcpio hooks:

  .. code:: bash

    make install-initcpio

License
=======

Archiso is licensed under the terms of the **GPL-3.0-or-later** (see `LICENSE <LICENSE>`_).

============
Contributing
============

These are the contribution guidelines for archiso.
All contributions fall under the terms of the GPL-3.0-or-later (see `LICENSE <LICENSE>`_).

Editorconfig
============

A top-level editorconfig file is provided. Please configure your text editor to use it.

Linting
=======

All ash and bash scripts are linted using shellcheck:

  .. code:: bash

    make lint

Testing
=======

Contributors are expected to test their contributions by building the releng profile and running the resulting image
using `run_archiso <scripts/run_archiso.sh>`_.

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

Changelog
=========

When adding, changing or removing something in a merge request, add a sentence to the `CHANGELOG.rst <CHANGELOG.rst>`_
explaining it.
The changelog entry needs to be added to the unreleased section at the top, as that section is used for the next
release.

Merge requests and signed commits
=================================

Merge requests are not required to contain signed commits (using ``git commit -S`` - see `man 1 git-commit
<https://man.archlinux.org/man/git-commit.1>`_).
The project maintainers may rebase a given merge request branch at their discretion (if possible), which may remove
signed commits.

The tip of the project's default branch is required to be a signed commit by the project maintainers.
For external contributors this means, that their merge request will be merged using ``--no-ff`` (see `man 1 git-merge
<https://man.archlinux.org/man/git-merge.1>`_) in a signed merge commit, while contributions by the project maintainers
may be merged using ``--ff`` when the top-most commit of the source branch is signed by a valid PGP key of the given
maintainer.

Testing
=======

Contributors are expected to test their contributions by building the releng profile and running the resulting image
using `run_archiso <scripts/run_archiso.sh>`_.

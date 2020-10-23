=======
profile
=======

An archiso profile consists of several configuration files and a directory for files to be added to the resulting image.

pacman.conf
===========

A configuration for pacman is required per profile.

Some configuration options will not be used or will be modified:

* `CacheDir`: the profile's option is **only** used if it is not the default (i.e. `/var/cache/pacman/pkg`) and if it is
  not the same as the system's option. In all other cases the system's pacman cache is used.
* `HookDir`: it is **always** set to the `/etc/pacman.d/hooks` airootfs directory in the work directories airootfs to
  allow modification via the profile and ensure interoparability with hosts using dracut (see #73 for further
  information)
* `RootDir`: it is **always** removed, as setting it explicitely otherwise refers to the host's root filesystem (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)
* `LogFile`: it is **always** removed, as setting it explicitely otherwise refers to the host's pacman log file (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)
* `DBPath`: it is **always** removed, as setting it explicitely otherwise refers to the host's pacman database (see
  `man 8 pacman` for further information on the `-r` option used by `pacstrap`)

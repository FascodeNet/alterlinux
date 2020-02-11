
## AlterLinux - ArchLinux-derived OS made in Japan aimed at being usable by anyone

![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=appveyor)
![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=appveyor)
![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)

## Overview
  
Alter Linux is a new OS developed based on Arch Linux.


## Repositories and software

### Repositories
- [SereneTeam/alter-repo](https://github.com/SereneTeam/alter-repo)  
All mirror servers are synchronized with this repository.  


### Software
The source code of the original software included in Alter Linux is below.
The first of all packages is [here](https://github.com/SereneTeam/alterlinux/blob/master/packages.x86_64).

- [EG-Installer](https://github.com/Hayao0819/EG-Installer)([PKGBUILD](https://github.com/Hayao0819/EG-Installer-PKGBUILD))
- [plymouth-theme-alter](https://github.com/yamad-linuxer/plymouth-theme-alter)([PKGBUILD](https://github.com/Hayao0819/plymouth-theme-alter))

The source code for software not in the AUR can be found below.

- [calamares](https://gitlab.manjaro.org/applications/calamares)([PKGBUILD](https://gitlab.manjaro.org/packages/extra/calamares))


## build
You need to build in ArchLinux environment.
Please install `archiso` package beforehand.

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build.sh
```

### build.sh options

#### basic
Please execute as it is. The default password is `alter`. Plymouth has been disabled.

#### options
- Enable Plymouth ： `-b`
- Change the password ： `-p <password>`

Example: Enable Plymouth and change the password to `ilovearch`.

```bash
./build.sh -b -p 'ilovealter'
```

## Developer
- [Hayao0819](https://twitter.com/Hayao0819)
- [lap1sid](https://twitter.com/Pixel_3a)
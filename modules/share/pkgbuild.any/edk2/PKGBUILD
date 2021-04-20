# Maintainer: David Runge <dvzrv@archlinux.org>

_brotli_ver=1.0.7
_openssl_ver=1.1.1g
pkgbase=edk2
pkgname=('edk2-shell' 'edk2-ovmf')
pkgver=202005
pkgrel=3
pkgdesc="Modern, feature-rich firmware development environment for the UEFI specifications"
arch=('any')
url="https://github.com/tianocore/edk2"
license=('BSD')
makedepends=('acpica' 'iasl' 'util-linux-libs' 'nasm' 'python')
options=(!makeflags)
source=("$pkgbase-$pkgver.tar.gz::https://github.com/tianocore/${pkgbase}/archive/${pkgbase}-stable${pkgver}.tar.gz"
        "https://www.openssl.org/source/openssl-${_openssl_ver}.tar.gz"{,.asc}
        "brotli-${_brotli_ver}.tar.gz::https://github.com/google/brotli/archive/v${_brotli_ver}.tar.gz"
        "${pkgbase}-202005-openssl-1.1.1g.patch"
        "50-edk2-ovmf-i386-secure.json"
        "50-edk2-ovmf-x86_64-secure.json"
        "60-edk2-ovmf-i386.json"
        "60-edk2-ovmf-x86_64.json")
sha512sums=('864e5b8babb28eea05f59e17581209c853c004993842a7a6b104e96bd1fd29d9dd3a1545fb44639f2442acc51b078c4996621e1f927fbf449dc1b86421b432ac'
            '01e3d0b1bceeed8fb066f542ef5480862001556e0f612e017442330bbd7e5faee228b2de3513d7fc347446b7f217e27de1003dc9d7214d5833b97593f3ec25ab'
            'SKIP'
            'a82362aa36d2f2094bca0b2808d9de0d57291fb3a4c29d7c0ca0a37e73087ec5ac4df299c8c363e61106fccf2fe7f58b5cf76eb97729e2696058ef43b1d3930a'
            '3605c67d9c8870562086f63e96ffe8039cb394266298b382df61e12c777b6c37a2d2eb3fd5147cb3f00fabddc6dba139ba53da42ea81b1cbeb8f587c6d4cc251'
            '55e4187b11b27737f61e528c02ff43b9381c0cb09140e803531616766f9cb9401115d88d946b56171784cc028f9571279640eb39b6a9fa8e02ec0c8d1b036a3e'
            'a1236585b30d720540de2e9527d8c90ff2d428e800b3da545b23461dc698dc91fe441b62bb8cbca76e08f4ec1eb485619e9ab26157deb06e7fb33e7f5f9dd8b6'
            'c81e072aabfb01d29cf5194111524e2c4c8684979de6b6793db10299c95bb94f7b1d0a98b057df0664d7a894a2b40e9b4c3576112fae400a95eaf5fe5fc9369b'
            '2030dc1d49d56fce8af56c5777fd40f04041e39ff806dd8c021e161227bdd646982024db6758230b8332dc68f16bc6918e1d54ad3c022e21e148d6b65ea778b3')
validpgpkeys=('8657ABB260F056B1E5190839D9C4D26D0E604491') # Matt Caswell <matt@openssl.org>
_arch_list=('IA32' 'X64')
_build_type='RELEASE'
_build_plugin='GCC5'

prepare() {
  mv -v "$pkgbase-$pkgbase-stable$pkgver" "$pkgbase-$pkgver"
  cd "$pkgbase-$pkgver"

  # applying fixes to build against openssl-1.1.1g
  patch -Np1 -i "../${pkgbase}-202005-openssl-1.1.1g.patch"
  # symlinking openssl into place
  rm -rfv CryptoPkg/Library/OpensslLib/openssl
  ln -sfv "${srcdir}/openssl-$_openssl_ver" CryptoPkg/Library/OpensslLib/openssl
  # copying required pre-generated header into place (to not also have to patch openssl)
  cp -v CryptoPkg/Library/Include/internal/dso_conf.h CryptoPkg/Library/OpensslLib/openssl/include/crypto/

  # symlinking brotli into place
  rm -rfv BaseTools/Source/C/BrotliCompress/brotli MdeModulePkg/Library/BrotliCustomDecompressLib/brotli
  ln -sfv "${srcdir}/brotli-${_brotli_ver}" BaseTools/Source/C/BrotliCompress/brotli
  ln -sfv "${srcdir}/brotli-${_brotli_ver}" MdeModulePkg/Library/BrotliCustomDecompressLib/brotli

  # -Werror, not even once
  sed -e 's/ -Werror//g' \
      -i BaseTools/Conf/*.template BaseTools/Source/C/Makefiles/*.makefile
}

build() {
  cd "$pkgbase-$pkgver"
  local _arch
  make -C BaseTools
  . edksetup.sh
  for _arch in ${_arch_list[@]}; do
    # shell
    echo "Building shell (${_arch})."
    BaseTools/BinWrappers/PosixLike/build -p ShellPkg/ShellPkg.dsc \
                                          -a "${_arch}" \
                                          -b "${_build_type}" \
                                          -n "$(nproc)" \
                                          -t "${_build_plugin}"
    # ovmf
    if [[ "${_arch}" == 'IA32' ]]; then
      echo "Building ovmf (${_arch}) with secure boot"
      OvmfPkg/build.sh -p OvmfPkg/OvmfPkgIa32.dsc \
                       -a "${_arch}" \
                       -b "${_build_type}" \
                       -n "$(nproc)" \
                       -t "${_build_plugin}" \
                       -D LOAD_X64_ON_IA32_ENABLE \
                       -D NETWORK_IP6_ENABLE \
                       -D TPM_ENABLE \
                       -D HTTP_BOOT_ENABLE \
                       -D TLS_ENABLE \
                       -D FD_SIZE_2MB \
                       -D SECURE_BOOT_ENABLE \
                       -D SMM_REQUIRE \
                       -D EXCLUDE_SHELL_FROM_FD
      mv -v Build/Ovmf{Ia32,IA32-secure}
      echo "Building ovmf (${_arch}) without secure boot"
      OvmfPkg/build.sh -p OvmfPkg/OvmfPkgIa32.dsc \
                       -a "${_arch}" \
                       -b "${_build_type}" \
                       -n "$(nproc)" \
                       -t "${_build_plugin}" \
                       -D LOAD_X64_ON_IA32_ENABLE \
                       -D NETWORK_IP6_ENABLE \
                       -D TPM_ENABLE \
                       -D HTTP_BOOT_ENABLE \
                       -D TLS_ENABLE \
                       -D FD_SIZE_2MB
      mv -v Build/Ovmf{Ia32,IA32}
    fi
    if [[ "${_arch}" == 'X64' ]]; then
      echo "Building ovmf (${_arch}) with secure boot"
      OvmfPkg/build.sh -p "OvmfPkg/OvmfPkg${_arch}.dsc" \
                       -a "${_arch}" \
                       -b "${_build_type}" \
                       -n "$(nproc)" \
                       -t "${_build_plugin}" \
                       -D NETWORK_IP6_ENABLE \
                       -D TPM_ENABLE \
                       -D FD_SIZE_2MB \
                       -D TLS_ENABLE \
                       -D HTTP_BOOT_ENABLE \
                       -D SECURE_BOOT_ENABLE \
                       -D SMM_REQUIRE \
                       -D EXCLUDE_SHELL_FROM_FD
      mv -v Build/OvmfX64{,-secure}
      echo "Building ovmf (${_arch}) without secure boot"
      OvmfPkg/build.sh -p "OvmfPkg/OvmfPkg${_arch}.dsc" \
                       -a "${_arch}" \
                       -b "${_build_type}" \
                       -n "$(nproc)" \
                       -t "${_build_plugin}" \
                       -D NETWORK_IP6_ENABLE \
                       -D TPM_ENABLE \
                       -D FD_SIZE_2MB \
                       -D TLS_ENABLE \
                       -D HTTP_BOOT_ENABLE
    fi
  done
}

package_edk2-shell() {
  pkgdesc="EDK2 UEFI Shell"
  provides=('uefi-shell')
  cd "$pkgbase-$pkgver"
  local _arch
  # minimal UEFI shell, as defined in ShellPkg/Application/Shell/ShellPkg.inf
  local _min='7C04A583-9E3E-4f1c-AD65-E05268D0B4D1'
  # full UEFI shell, as defined in ShellPkg/ShellPkg.dsc
  local _full='EA4BB293-2D7F-4456-A681-1F22F42CD0BC'
  for _arch in ${_arch_list[@]}; do
    install -vDm 644 "Build/Shell/${_build_type}_${_build_plugin}/${_arch}/Shell_${_min}.efi" \
      "${pkgdir}/usr/share/${pkgname}/${_arch,,}/Shell.efi"
    install -vDm 644 "Build/Shell/${_build_type}_${_build_plugin}/${_arch}/Shell_${_full}.efi" \
      "${pkgdir}/usr/share/${pkgname}/${_arch,,}/Shell_Full.efi"
  done
  # license
  install -vDm 644 License.txt -t "${pkgdir}/usr/share/licenses/${pkgname}"
  # docs
  install -vDm 644 {ReadMe.rst,Maintainers.txt} \
    -t "${pkgdir}/usr/share/doc/${pkgname}"
}

package_edk2-ovmf() {
  pkgdesc="Open Virtual Machine Firmware to support firmware for Virtual Machines"
  provides=('ovmf')
  conflicts=('ovmf')
  replaces=('ovmf')
  license+=('MIT')
  install="${pkgname}.install"
  cd "$pkgbase-$pkgver"
  local _arch
  # installing the various firmwares
  for _arch in ${_arch_list[@]}; do
    # installing OVMF.fd for xen: https://bugs.archlinux.org/task/58635
    install -vDm 644 "Build/Ovmf${_arch}/${_build_type}_${_build_plugin}/FV/OVMF.fd" \
      -t "${pkgdir}/usr/share/${pkgname}/${_arch,,}"
    install -vDm 644 "Build/Ovmf${_arch}/${_build_type}_${_build_plugin}/FV/OVMF_CODE.fd" \
      -t "${pkgdir}/usr/share/${pkgname}/${_arch,,}"
    install -vDm 644 "Build/Ovmf${_arch}/${_build_type}_${_build_plugin}/FV/OVMF_VARS.fd" \
      -t "${pkgdir}/usr/share/${pkgname}/${_arch,,}"
    install -vDm 644 "Build/Ovmf${_arch}-secure/${_build_type}_${_build_plugin}/FV/OVMF_CODE.fd" \
      "${pkgdir}/usr/share/${pkgname}/${_arch,,}/OVMF_CODE.secboot.fd"
  done
  # installing qemu descriptors in accordance with qemu:
  # https://git.qemu.org/?p=qemu.git;a=tree;f=pc-bios/descriptors
  # https://bugs.archlinux.org/task/64206
  install -vDm 644 ../*"${pkgname}"*.json -t "${pkgdir}/usr/share/qemu/firmware"
  # adding symlink for previous ovmf location
  # https://bugs.archlinux.org/task/66528
  ln -svf "/usr/share/${pkgname}" "${pkgdir}/usr/share/ovmf"
  # adding a symlink for applications with questionable heuristics (such as lxd)
  ln -svf "/usr/share/${pkgname}" "${pkgdir}/usr/share/OVMF"
  # licenses
  install -vDm 644 License.txt -t "${pkgdir}/usr/share/licenses/${pkgname}"
  install -vDm 644 OvmfPkg/License.txt \
    "${pkgdir}/usr/share/licenses/${pkgname}/OvmfPkg.License.txt"
  # docs
  install -vDm 644 {OvmfPkg/README,ReadMe.rst,Maintainers.txt} \
    -t "${pkgdir}/usr/share/doc/${pkgname}"
}

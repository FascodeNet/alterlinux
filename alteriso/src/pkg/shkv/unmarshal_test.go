package shkv

import "testing"

func Test_Unmarshal(t *testing.T) {
	script := `
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
    'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
alteriso_modules=("base" "network-manager")
`
	to := struct {
		Buildmodes []string `shkv:"buildmodes"`
		Bootmodes  []string `shkv:"bootmodes"`
		Arch       string   `shkv:"arch"`
		modules    []string `shkv:"alteriso_modules"`
	}{}

	if err := Unmarshal(script, &to); err != nil {
		t.Fatal(err)
	}

	if len(to.Bootmodes) != 2 {
		t.Fatalf("len(to.Bootmodes) != 2: %d", len(to.Bootmodes))
	}
	if to.Bootmodes[0] != "bios.syslinux" {
		t.Fatalf("to.Bootmodes[0] != bios.syslinux: %s", to.Bootmodes[0])
	}
	if to.Bootmodes[1] != "uefi.systemd-boot" {
		t.Fatalf("to.Bootmodes[1] != uefi.systemd-boot: %s", to.Bootmodes[1])
	}
	if to.Arch != "x86_64" {
		t.Fatalf("to.Arch != x86_64: %s", to.Arch)
	}
    if len(to.modules) != 2 {
        t.Fatalf("len(to.modules) != 2: %d", len(to.modules))
    }
    if to.modules[0] != "base" {
        t.Fatalf("to.modules[0] != base: %s", to.modules[0])
    }
    if to.modules[1] != "network-manager" {
        t.Fatalf("to.modules[1] != network-manager: %s", to.modules[1])
    }
}

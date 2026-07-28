// LLM Generated: Created by Claude
package profilegen

import (
	"encoding/json"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func TestGenerateAppliesVariantsAfterTheProfile(t *testing.T) {
	root := t.TempDir()
	sourceDir := filepath.Join(root, "xfce")
	modulesDir := filepath.Join(root, "modules")
	moduleDir := filepath.Join(modulesDir, "input")
	bootloadersDir := filepath.Join(root, "bootloaders")
	outputDir := filepath.Join(root, "output")

	writeTestFile(t, filepath.Join(sourceDir, "profiledef.json"), `{
		"arch": "x86_64",
		"modules": ["input"],
		"os_name": "Test Linux"
	}`)
	writeTestFile(t, filepath.Join(sourceDir, "profiledef.sh"), "#!/usr/bin/env bash\niso_name=\"test\"\n")
	writeTestFile(t, filepath.Join(sourceDir, "pacman.conf"), "profile\n")
	writeTestFile(t, filepath.Join(sourceDir, "packages.x86_64"), "base\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs.any", "etc", "origin"), "profile\n")
	writeTestFile(t, filepath.Join(moduleDir, "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": "any"
	}`)
	writeTestFile(t, filepath.Join(moduleDir, "airootfs.any", "etc", "origin"), "module\n")

	variantDir := filepath.Join(moduleDir, "variants", "japanese")
	writeTestFile(t, filepath.Join(variantDir, "packages.x86_64"), "fcitx5-mozc\n")
	// The module ranks below the profile, but its variant still wins.
	writeTestFile(t, filepath.Join(variantDir, "airootfs.any", "etc", "origin"), "input:japanese\n")
	writeTestFile(t, filepath.Join(bootloadersDir, "syslinux", "syslinux.cfg"), "\n")

	loaded, err := profile.Load(sourceDir, modulesDir, []string{"japanese"})
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	if err := Generate(loaded, outputDir, Options{BootloadersDir: bootloadersDir, NoConfirm: true}); err != nil {
		t.Fatalf("Generate() error = %v", err)
	}

	if got, want := readTestFile(t, filepath.Join(outputDir, "airootfs", "etc", "origin")), "input:japanese\n"; got != want {
		t.Errorf("airootfs overlay = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(outputDir, "packages.x86_64")), "base\nfcitx5-mozc\n"; got != want {
		t.Errorf("packages.x86_64 = %q, want %q", got, want)
	}
	if got := readTestFile(t, filepath.Join(outputDir, "profiledef.sh")); !strings.Contains(got, `iso_name+="-japanese"`) {
		t.Error("profiledef.sh does not name the ISO after the variant")
	}

	var config struct {
		Variants []string `json:"variants"`
		Modules  []string `json:"modules"`
	}
	content := readTestFile(t, filepath.Join(outputDir, "profiledef.json"))
	if err := json.Unmarshal([]byte(content), &config); err != nil {
		t.Fatalf("failed to decode profiledef.json: %v", err)
	}
	if got, want := config.Variants, []string{"japanese"}; !reflect.DeepEqual(got, want) {
		t.Errorf("variants = %v, want %v", got, want)
	}
	if got, want := config.Modules, []string{"input", "input:japanese"}; !reflect.DeepEqual(got, want) {
		t.Errorf("modules = %v, want %v", got, want)
	}
}

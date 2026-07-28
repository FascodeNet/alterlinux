// LLM Generated: Created by Claude
package profilegen

import (
	"encoding/json"
	"path/filepath"
	"reflect"
	"slices"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/samber/lo"
)

func TestGeneratedConfigCarriesResolvedOptions(t *testing.T) {
	root := t.TempDir()
	sourceDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	bootloadersDir := filepath.Join(root, "bootloaders")
	outputDir := filepath.Join(root, "output")

	writeTestFile(t, filepath.Join(sourceDir, "profiledef.json"), `{
		"arch": "x86_64",
		"modules": ["example"],
		"os_name": "Test Linux",
		"kernel_name": "linux-test",
		"username": "live",
		"cow_spacesize": "2G",
		"module_options": {"example": {"usershell": "/usr/bin/zsh"}}
	}`)
	writeTestFile(t, filepath.Join(sourceDir, "profiledef.sh"), "#!/usr/bin/env bash\narch=x86_64\n")
	writeTestFile(t, filepath.Join(sourceDir, "pacman.conf"), "profile\n")
	writeTestFile(t, filepath.Join(sourceDir, "packages.x86_64"), "example\n")
	writeTestFile(t, filepath.Join(modulesDir, "example", "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": "any",
		"options": {
			"usershell": {"type": "string", "default": "/bin/bash"},
			"autologin": {"type": "bool", "default": true}
		}
	}`)
	writeTestFile(t, filepath.Join(bootloadersDir, "syslinux", "syslinux.cfg"), "\n")

	loaded, err := profile.Load(sourceDir, modulesDir)
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	if err := Generate(loaded, outputDir, Options{BootloadersDir: bootloadersDir, NoConfirm: true}); err != nil {
		t.Fatalf("Generate() error = %v", err)
	}

	var config map[string]any
	content := readTestFile(t, filepath.Join(outputDir, "profiledef.json"))
	if err := json.Unmarshal([]byte(content), &config); err != nil {
		t.Fatalf("failed to decode profiledef.json: %v", err)
	}

	want := []string{"arch", "cow_spacesize", "kernel_name", "module_options", "modules", "os_name", "username"}
	if got := slices.Sorted(slices.Values(lo.Keys(config))); !reflect.DeepEqual(got, want) {
		t.Errorf("profiledef.json keys = %v, want %v", got, want)
	}

	wantOptions := map[string]any{
		"example": map[string]any{"usershell": "/usr/bin/zsh", "autologin": true},
	}
	if got := config["module_options"]; !reflect.DeepEqual(got, wantOptions) {
		t.Errorf("module_options = %#v, want %#v", got, wantOptions)
	}
}

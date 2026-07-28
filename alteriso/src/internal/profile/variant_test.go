// LLM Generated: Created by Claude
package profile

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/samber/lo"
)

func writeVariantFile(t *testing.T, ownerDir, variant, name, content string) {
	t.Helper()

	path := filepath.Join(ownerDir, variantsDirName, variant, name)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("failed to create variant directory: %v", err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("failed to write variant file: %v", err)
	}
}

func TestParseVariants(t *testing.T) {
	tests := []struct {
		name      string
		selection string
		want      []string
		wantError string
	}{
		{name: "empty selection", selection: ""},
		{name: "single name", selection: "japanese", want: []string{"japanese"}},
		{name: "order is kept", selection: "japanese,nvidia", want: []string{"japanese", "nvidia"}},
		{name: "spaces and blanks are dropped", selection: " japanese , ,nvidia ", want: []string{"japanese", "nvidia"}},
		{name: "duplicate selection", selection: "japanese,japanese", wantError: "selected more than once"},
		{name: "path instead of a name", selection: "../japanese", wantError: "must be a directory name"},
		// filepath.Base はこの 2 つを素通しするので、単独で確かめる
		{name: "parent directory", selection: "..", wantError: "must be a directory name"},
		{name: "current directory", selection: ".", wantError: "must be a directory name"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseVariants(tt.selection)
			if tt.wantError != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantError) {
					t.Fatalf("ParseVariants() error = %v, want error containing %q", err, tt.wantError)
				}
				return
			}
			if err != nil {
				t.Fatalf("ParseVariants() error = %v", err)
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("ParseVariants() = %#v, want %#v", got, tt.want)
			}
		})
	}
}

// TestLoadOrdersVariantsAfterEveryBaseSource pins the merge order the whole
// design rests on: variants win over the profile, and a later variant wins
// over an earlier one.
func TestLoadOrdersVariantsAfterEveryBaseSource(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "xfce")
	modulesDir := filepath.Join(root, "modules")

	inputDir := writeModuleConfig(t, modulesDir, "input", validModuleConfig(AnyArchitecture))
	writeVariantFile(t, inputDir, "japanese", "packages", "fcitx5-mozc\n")
	writeProfileConfig(t, profileDir, map[string]any{
		"arch":    "x86_64",
		"modules": []string{"input"},
	})
	writeVariantFile(t, profileDir, "japanese", "packages", "otf-ipafont\n")
	writeVariantFile(t, profileDir, "nvidia", "packages", "nvidia\n")

	loaded, err := Load(profileDir, modulesDir, []string{"japanese", "nvidia"})
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	want := []string{"input", "xfce", "input:japanese", "xfce:japanese", "xfce:nvidia"}
	got := lo.Map(loaded.Sources(), func(source Source, _ int) string { return source.Name })
	if !reflect.DeepEqual(got, want) {
		t.Errorf("Sources() = %v, want %v", got, want)
	}
	if got, want := loaded.Variants(), []string{"japanese", "nvidia"}; !reflect.DeepEqual(got, want) {
		t.Errorf("Variants() = %v, want %v", got, want)
	}
}

// TestLoadRejectsEmptyVariantArch separates an omitted "arch" from an explicit
// empty array: only the former inherits the owner's architectures.
func TestLoadRejectsEmptyVariantArch(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "xfce")
	modulesDir := filepath.Join(root, "modules")

	writeModuleConfig(t, modulesDir, "input", validModuleConfig([]string{"x86_64"}))
	writeProfileConfig(t, profileDir, map[string]any{
		"arch":    "x86_64",
		"modules": []string{"input"},
	})
	writeVariantFile(t, profileDir, "japanese", "alteriso.json", `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": []
	}`)

	_, err := Load(profileDir, modulesDir, []string{"japanese"})
	if err == nil {
		t.Fatal("Load() succeeded, want an error for the empty architecture array")
	}
	if !strings.Contains(err.Error(), `must declare "arch" as "any" or a non-empty array`) {
		t.Fatalf("Load() error = %q, want the architecture validation error", err)
	}
}

func TestLoadRejectsVariantNoSourceProvides(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "xfce")
	modulesDir := filepath.Join(root, "modules")
	writeModuleConfig(t, modulesDir, "input", validModuleConfig(AnyArchitecture))
	writeProfileConfig(t, profileDir, map[string]any{
		"arch":    "x86_64",
		"modules": []string{"input"},
	})

	_, err := Load(profileDir, modulesDir, []string{"japanse"})
	if err == nil {
		t.Fatal("Load() succeeded, want an error for the unknown variant")
	}
	if !strings.Contains(err.Error(), `variant "japanse" is not provided`) {
		t.Fatalf("Load() error = %q, want it to name the unknown variant", err)
	}
}

func TestLoadAppliesVariantManifest(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "xfce")
	modulesDir := filepath.Join(root, "modules")

	writeModuleConfig(t, modulesDir, "user", moduleConfigWithOptions(map[string]any{
		"usershell": map[string]any{"type": "string", "default": "/bin/bash"},
	}))
	writeProfileConfig(t, profileDir, map[string]any{
		"arch":    "x86_64",
		"modules": []string{"user"},
	})
	writeVariantFile(t, profileDir, "japanese", "alteriso.json", `{
		"manifest_version": 1,
		"module_version": 1,
		"append_kernel_param": ["lang=ja"],
		"module_options": {"user": {"usershell": "/usr/bin/zsh"}}
	}`)

	loaded, err := Load(profileDir, modulesDir, []string{"japanese"})
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	want := map[string]map[string]any{"user": {"usershell": "/usr/bin/zsh"}}
	if got := loaded.ModuleOptions(); !reflect.DeepEqual(got, want) {
		t.Errorf("ModuleOptions() = %#v, want %#v", got, want)
	}

	unit, found := lo.Find(loaded.Modules(), func(module Module) bool { return module.Name == "xfce:japanese" })
	if !found {
		t.Fatal("variant unit is missing from Modules()")
	}
	if got, want := unit.Definition.AppendKernelParam, []string{"lang=ja"}; !reflect.DeepEqual(got, want) {
		t.Errorf("variant kernel parameters = %v, want %v", got, want)
	}
	// The manifest omits "arch", so the variant inherits the profile's reach.
	if !unit.Definition.Arch.IsAny() {
		t.Errorf("variant arch = %v, want any", unit.Definition.Arch)
	}
}

// LLM Generated: Created by Claude
package profile

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func writeProfileConfig(t *testing.T, dir string, config map[string]any) {
	t.Helper()

	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("failed to create profile directory: %v", err)
	}
	content, err := json.Marshal(config)
	if err != nil {
		t.Fatalf("failed to marshal profile config: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, profileManifestName), content, 0o644); err != nil {
		t.Fatalf("failed to write profile config: %v", err)
	}
}

func moduleConfigWithOptions(options map[string]any) map[string]any {
	config := validModuleConfig(AnyArchitecture)
	config["options"] = options
	return config
}

func loadWithOptions(t *testing.T, moduleConfig map[string]any, moduleOptions map[string]any) (*Profile, error) {
	t.Helper()

	root := t.TempDir()
	profileDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	writeModuleConfig(t, modulesDir, "example", moduleConfig)

	config := map[string]any{
		"arch":    "x86_64",
		"modules": []string{"example"},
	}
	if moduleOptions != nil {
		config["module_options"] = moduleOptions
	}
	writeProfileConfig(t, profileDir, config)

	return Load(profileDir, modulesDir, nil)
}

func TestLoadResolvesModuleOptions(t *testing.T) {
	moduleConfig := moduleConfigWithOptions(map[string]any{
		"usershell": map[string]any{"type": "string", "default": "/bin/bash"},
		"autologin": map[string]any{"type": "bool", "default": true},
		"groups":    map[string]any{"type": "string[]", "default": []string{"wheel"}},
		"theme":     map[string]any{"type": "string"},
	})

	loaded, err := loadWithOptions(t, moduleConfig, map[string]any{
		"example": map[string]any{
			"usershell": "/usr/bin/zsh",
			"groups":    []string{"wheel", "audio"},
		},
	})
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	want := map[string]map[string]any{
		"example": {
			"usershell": "/usr/bin/zsh",
			"autologin": true,
			"groups":    []string{"wheel", "audio"},
		},
	}
	if got := loaded.ModuleOptions(); !reflect.DeepEqual(got, want) {
		t.Errorf("ModuleOptions() = %#v, want %#v", got, want)
	}
}

func TestLoadRejectsInvalidModuleOptions(t *testing.T) {
	tests := []struct {
		name          string
		moduleOptions map[string]any
		declared      map[string]any
		wantError     string
	}{
		{
			name:      "undeclared option",
			declared:  map[string]any{"usershell": map[string]any{"type": "string"}},
			wantError: `module "example" does not declare option "shell"`,
			moduleOptions: map[string]any{
				"example": map[string]any{"shell": "/bin/bash"},
			},
		},
		{
			name:      "unknown module",
			declared:  map[string]any{},
			wantError: `configures module "missing" which is not loaded`,
			moduleOptions: map[string]any{
				"missing": map[string]any{"shell": "/bin/bash"},
			},
		},
		{
			name:      "type mismatch",
			declared:  map[string]any{"autologin": map[string]any{"type": "bool"}},
			wantError: `option "autologin": expected a bool, got string`,
			moduleOptions: map[string]any{
				"example": map[string]any{"autologin": "yes"},
			},
		},
		{
			name:      "missing required option",
			declared:  map[string]any{"branding": map[string]any{"type": "string", "required": true}},
			wantError: `module "example" requires option "branding"`,
		},
		{
			name:      "unsupported declared type",
			declared:  map[string]any{"retries": map[string]any{"type": "int"}},
			wantError: `declares unsupported type "int"`,
		},
		{
			name:      "default conflicts with required",
			declared:  map[string]any{"branding": map[string]any{"type": "string", "required": true, "default": "alter"}},
			wantError: "cannot be required and have a default",
		},
		{
			name:      "default does not match the declared type",
			declared:  map[string]any{"autologin": map[string]any{"type": "bool", "default": "yes"}},
			wantError: "has an invalid default",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := loadWithOptions(t, moduleConfigWithOptions(tt.declared), tt.moduleOptions)
			if err == nil {
				t.Fatalf("Load() succeeded, want error containing %q", tt.wantError)
			}
			if !strings.Contains(err.Error(), tt.wantError) {
				t.Fatalf("Load() error = %q, want error containing %q", err, tt.wantError)
			}
		})
	}
}

func TestLoadRejectsUnknownProfileKeys(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	writeModuleConfig(t, modulesDir, "example", validModuleConfig(AnyArchitecture))
	writeProfileConfig(t, profileDir, map[string]any{
		"arch":      "x86_64",
		"modules":   []string{"example"},
		"usershell": "/bin/bash",
	})

	_, err := Load(profileDir, modulesDir, nil)
	if err == nil {
		t.Fatal("Load() succeeded, want an error for the unknown key")
	}
	if !strings.Contains(err.Error(), "usershell") {
		t.Fatalf("Load() error = %q, want it to name the unknown key", err)
	}
}

package profile

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeModuleConfig(t *testing.T, modulesDir, name string, config map[string]any) string {
	t.Helper()

	moduleDir := filepath.Join(modulesDir, name)
	if err := os.MkdirAll(moduleDir, 0o755); err != nil {
		t.Fatalf("failed to create module directory: %v", err)
	}
	content, err := json.Marshal(config)
	if err != nil {
		t.Fatalf("failed to marshal module config: %v", err)
	}
	if err := os.WriteFile(filepath.Join(moduleDir, "alteriso.json"), content, 0o644); err != nil {
		t.Fatalf("failed to write module config: %v", err)
	}
	return moduleDir
}

func validModuleConfig(arch any) map[string]any {
	return map[string]any{
		"manifest_version": 1,
		"module_version":   1,
		"arch":             arch,
	}
}

func TestNewModuleValidatesArch(t *testing.T) {
	tests := []struct {
		name      string
		arch      any
		omitArch  bool
		wantError string
	}{
		{
			name: "concrete architectures",
			arch: []string{"x86_64", "i686"},
		},
		{
			name: "any architecture",
			arch: AnyArchitecture,
		},
		{
			name:      "missing arch",
			omitArch:  true,
			wantError: `must declare "arch" as "any" or a non-empty array`,
		},
		{
			name:      "concrete architecture must be in an array",
			arch:      "x86_64",
			wantError: `"arch" only accepts "any" as a string`,
		},
		{
			name:      "arch must be a string or array",
			arch:      1,
			wantError: `"arch" must be "any" or an array of strings`,
		},
		{
			name:      "array item must be a string",
			arch:      []any{"x86_64", 1},
			wantError: `"arch" array item at index 1 must be a string`,
		},
		{
			name:      "empty architecture array",
			arch:      []string{},
			wantError: `must declare "arch" as "any" or a non-empty array`,
		},
		{
			name:      "empty architecture",
			arch:      []string{""},
			wantError: "contains an empty architecture",
		},
		{
			name:      "architecture with whitespace",
			arch:      []string{" x86_64"},
			wantError: "contains leading or trailing whitespace",
		},
		{
			name:      "duplicate architecture",
			arch:      []string{"x86_64", "x86_64"},
			wantError: `declares architecture "x86_64" more than once`,
		},
		{
			name:      "any must not appear in an array",
			arch:      []string{AnyArchitecture},
			wantError: `must declare the wildcard as "arch": "any"`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := map[string]any{
				"manifest_version": 1,
				"module_version":   1,
			}
			if !tt.omitArch {
				config["arch"] = tt.arch
			}
			moduleDir := writeModuleConfig(t, t.TempDir(), "example", config)

			module, err := LoadModule(moduleDir)
			if tt.wantError != "" {
				if err == nil {
					t.Fatalf("LoadModule() succeeded, want error containing %q", tt.wantError)
				}
				if !strings.Contains(err.Error(), tt.wantError) {
					t.Fatalf("LoadModule() error = %q, want error containing %q", err, tt.wantError)
				}
				return
			}
			if err != nil {
				t.Fatalf("LoadModule() error = %v", err)
			}
			if module.Name != "example" {
				t.Errorf("module.Name = %q, want %q", module.Name, "example")
			}
		})
	}
}

func TestModuleArchitecturesMarshalJSON(t *testing.T) {
	tests := []struct {
		name          string
		architectures ModuleArchitectures
		want          string
	}{
		{
			name:          "any",
			architectures: ModuleArchitectures{all: true},
			want:          `"any"`,
		},
		{
			name:          "concrete architectures",
			architectures: ModuleArchitectures{values: []string{"x86_64", "i686"}},
			want:          `["x86_64","i686"]`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := json.Marshal(tt.architectures)
			if err != nil {
				t.Fatalf("json.Marshal() error = %v", err)
			}
			if string(got) != tt.want {
				t.Errorf("json.Marshal() = %s, want %s", got, tt.want)
			}
		})
	}
}

func TestModuleSupportsArchitecture(t *testing.T) {
	tests := []struct {
		name   string
		arch   ModuleArchitectures
		target string
		want   bool
	}{
		{
			name:   "matching concrete architecture",
			arch:   ModuleArchitectures{values: []string{"x86_64", "i686"}},
			target: "i686",
			want:   true,
		},
		{
			name:   "unsupported concrete architecture",
			arch:   ModuleArchitectures{values: []string{"x86_64"}},
			target: "i686",
			want:   false,
		},
		{
			name:   "any matches concrete architecture",
			arch:   ModuleArchitectures{all: true},
			target: "riscv64",
			want:   true,
		},
		{
			name:   "empty target is not an architecture",
			arch:   ModuleArchitectures{all: true},
			target: "",
			want:   false,
		},
		{
			name:   "any is not a concrete target",
			arch:   ModuleArchitectures{all: true},
			target: AnyArchitecture,
			want:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			module := Module{
				Name: "example",
				Definition: ModuleDefinition{
					Arch: tt.arch,
				},
			}
			if got := module.SupportsArchitecture(tt.target); got != tt.want {
				t.Errorf("SupportsArchitecture(%q) = %t, want %t", tt.target, got, tt.want)
			}
		})
	}
}

func TestProfileForArchitectureValidatesModules(t *testing.T) {
	tests := []struct {
		name                 string
		profileArchitecture  string
		overrideArchitecture string
		moduleArch           any
		wantArchitecture     string
		wantError            string
	}{
		{
			name:                "profile architecture is supported",
			profileArchitecture: "x86_64",
			moduleArch:          []string{"x86_64"},
			wantArchitecture:    "x86_64",
		},
		{
			name:                "any module supports profile architecture",
			profileArchitecture: "riscv64",
			moduleArch:          AnyArchitecture,
			wantArchitecture:    "riscv64",
		},
		{
			name:                "profile architecture is unsupported",
			profileArchitecture: "i686",
			moduleArch:          []string{"x86_64"},
			wantError:           `module "example" does not support target architecture "i686" (supported architectures: x86_64)`,
		},
		{
			name:                 "override architecture is validated",
			profileArchitecture:  "x86_64",
			overrideArchitecture: "i686",
			moduleArch:           []string{"x86_64"},
			wantError:            `module "example" does not support target architecture "i686" (supported architectures: x86_64)`,
		},
		{
			name:                 "supported override architecture is retained",
			profileArchitecture:  "x86_64",
			overrideArchitecture: "i686",
			moduleArch:           []string{"x86_64", "i686"},
			wantArchitecture:     "i686",
		},
		{
			name:       "missing profile architecture",
			moduleArch: AnyArchitecture,
			wantError:  "profile architecture must not be empty",
		},
		{
			name:                "any is not a profile architecture",
			profileArchitecture: AnyArchitecture,
			moduleArch:          AnyArchitecture,
			wantError:           `profile architecture must be concrete and cannot be "any"`,
		},
		{
			name:                "profile architecture must not contain whitespace",
			profileArchitecture: " i686",
			moduleArch:          AnyArchitecture,
			wantError:           `profile architecture " i686" contains leading or trailing whitespace`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			root := t.TempDir()
			profileDir := filepath.Join(root, "profile")
			modulesDir := filepath.Join(root, "modules")
			if err := os.MkdirAll(profileDir, 0o755); err != nil {
				t.Fatalf("failed to create profile directory: %v", err)
			}
			writeModuleConfig(t, modulesDir, "example", validModuleConfig(tt.moduleArch))

			profileConfig, err := json.Marshal(map[string]any{
				"arch":    tt.profileArchitecture,
				"modules": []string{"example"},
			})
			if err != nil {
				t.Fatalf("failed to marshal profile config: %v", err)
			}
			if err := os.WriteFile(filepath.Join(profileDir, "profiledef.json"), profileConfig, 0o644); err != nil {
				t.Fatalf("failed to write profile config: %v", err)
			}

			loaded, err := Load(profileDir, modulesDir)
			if err == nil {
				loaded, err = loaded.ForArchitecture(tt.overrideArchitecture)
			}
			if tt.wantError != "" {
				if err == nil {
					t.Fatalf("profile resolution succeeded, want error containing %q", tt.wantError)
				}
				if !strings.Contains(err.Error(), tt.wantError) {
					t.Fatalf("profile resolution error = %q, want error containing %q", err, tt.wantError)
				}
				return
			}
			if err != nil {
				t.Fatalf("profile resolution error = %v", err)
			}
			if loaded.Definition.Arch != tt.wantArchitecture {
				t.Errorf("profile.Definition.Arch = %q, want %q", loaded.Definition.Arch, tt.wantArchitecture)
			}
		})
	}
}

func TestProfileCanResolveMultipleArchitectures(t *testing.T) {
	root := t.TempDir()
	profileDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	if err := os.MkdirAll(profileDir, 0o755); err != nil {
		t.Fatalf("failed to create profile directory: %v", err)
	}
	writeModuleConfig(t, modulesDir, "example", validModuleConfig([]string{"x86_64", "i686"}))
	if err := os.WriteFile(
		filepath.Join(profileDir, "profiledef.json"),
		[]byte(`{"arch":"x86_64","modules":["example"]}`),
		0o644,
	); err != nil {
		t.Fatalf("failed to write profile config: %v", err)
	}

	loaded, err := Load(profileDir, modulesDir)
	if err != nil {
		t.Fatalf("Loader.Load() error = %v", err)
	}
	x86, err := loaded.ForArchitecture("x86_64")
	if err != nil {
		t.Fatalf("ForArchitecture(x86_64) error = %v", err)
	}
	i686, err := loaded.ForArchitecture("i686")
	if err != nil {
		t.Fatalf("ForArchitecture(i686) error = %v", err)
	}

	if loaded.Definition.Arch != "x86_64" {
		t.Errorf("loaded profile architecture changed to %q", loaded.Definition.Arch)
	}
	if x86.Definition.Arch != "x86_64" || i686.Definition.Arch != "i686" {
		t.Errorf("resolved architectures = (%q, %q)", x86.Definition.Arch, i686.Definition.Arch)
	}
}

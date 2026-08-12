package profilegen

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func TestBuiltInModulesGenerateForDeclaredArchitectures(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	projectDir := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", ".."))
	modulesDir := filepath.Join(projectDir, "modules")

	entries, err := os.ReadDir(modulesDir)
	if err != nil {
		t.Fatalf("failed to read built-in modules: %v", err)
	}

	bootloadersDir := filepath.Join(t.TempDir(), "bootloaders")
	if err := os.MkdirAll(bootloadersDir, 0o755); err != nil {
		t.Fatalf("failed to create bootloaders directory: %v", err)
	}

	testedModules := 0
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		moduleDir := filepath.Join(modulesDir, entry.Name())
		if _, err := os.Stat(filepath.Join(moduleDir, "alteriso.json")); os.IsNotExist(err) {
			continue
		} else if err != nil {
			t.Fatalf("failed to inspect module %s: %v", entry.Name(), err)
		}
		testedModules++

		t.Run(entry.Name(), func(t *testing.T) {
			module, err := profile.LoadModule(moduleDir)
			if err != nil {
				t.Fatalf("profile.LoadModule() error = %v", err)
			}

			architectures := module.Definition.Arch.Values()
			if module.Definition.Arch.IsAny() {
				architectures = []string{"x86_64"}
			}
			for _, architecture := range architectures {
				t.Run(architecture, func(t *testing.T) {
					if err := module.ValidateArchitecture(architecture); err != nil {
						t.Fatalf("Module.ValidateArchitecture() error = %v", err)
					}

					profileDir := t.TempDir()
					definition, err := json.Marshal(profile.Definition{
						Arch:    architecture,
						Modules: []string{module.Name},
					})
					if err != nil {
						t.Fatalf("failed to encode profile definition: %v", err)
					}
					writeTestFile(t, filepath.Join(profileDir, "profiledef.json"), string(definition))
					writeTestFile(t, filepath.Join(profileDir, "profiledef.sh"), "#!/usr/bin/env bash\n")
					writeTestFile(t, filepath.Join(profileDir, "pacman.conf"), "[options]\n")

					loaded, err := profile.Load(profileDir, modulesDir)
					if err != nil {
						t.Fatalf("profile.Load() error = %v", err)
					}
					outputDir := filepath.Join(t.TempDir(), "generated")
					if err := Generate(loaded, outputDir, Options{BootloadersDir: bootloadersDir}); err != nil {
						t.Fatalf("Generate() error = %v", err)
					}
					for _, generated := range []string{
						"alteriso.json",
						"bootstrap_packages." + architecture,
						"bootstrap_packages_aur." + architecture,
						"injecter.sh",
						"packages_aur." + architecture,
						"packages." + architecture,
						"pacman.conf",
						"profiledef.json",
						"profiledef.sh",
					} {
						if _, err := os.Stat(filepath.Join(outputDir, generated)); err != nil {
							t.Errorf("generated file %s is missing: %v", generated, err)
						}
					}
				})
			}
		})
	}

	if testedModules == 0 {
		t.Fatal("no built-in modules were found")
	}
}

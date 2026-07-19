package profilegen

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/buildinfo"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func writeTestFile(t *testing.T, filename, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(filename), 0o755); err != nil {
		t.Fatalf("failed to create parent directory: %v", err)
	}
	if err := os.WriteFile(filename, []byte(content), 0o644); err != nil {
		t.Fatalf("failed to write %s: %v", filename, err)
	}
}

func readTestFile(t *testing.T, filename string) string {
	t.Helper()
	content, err := os.ReadFile(filename)
	if err != nil {
		t.Fatalf("failed to read %s: %v", filename, err)
	}
	return string(content)
}

func TestGeneratorComposesArchisoProfile(t *testing.T) {
	root := t.TempDir()
	sourceDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	moduleDir := filepath.Join(modulesDir, "example")
	bootloadersDir := filepath.Join(root, "bootloaders")
	outputDir := filepath.Join(root, "output")

	writeTestFile(t, filepath.Join(sourceDir, "profiledef.json"), `{
		"arch": "x86_64",
		"modules": ["example"],
		"os_name": "Test Linux",
		"kernel_name": "linux-test",
		"cow_spacesize": "2G",
		"injects": {"post_hook": ["profile_hook"]}
	}`)
	writeTestFile(t, filepath.Join(sourceDir, "profiledef.sh"), "#!/usr/bin/env bash\narch=x86_64\n")
	writeTestFile(t, filepath.Join(sourceDir, "pacman.conf"), "profile-base\n")
	writeTestFile(t, filepath.Join(sourceDir, "pacman.conf.any"), "profile-any\n")
	writeTestFile(t, filepath.Join(sourceDir, "pacman.conf.x86_64"), "profile-arch\n")
	writeTestFile(t, filepath.Join(sourceDir, "packages"), "d-profile-base\nshared\n")
	writeTestFile(t, filepath.Join(sourceDir, "packages.any.d", "common"), "e-profile-any\n")
	writeTestFile(t, filepath.Join(sourceDir, "packages.x86_64"), "f-profile-arch\n")
	writeTestFile(t, filepath.Join(sourceDir, "bootstrap_packages.any"), "profile-bootstrap-any\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs", "etc", "profile-base"), "base\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs.any", "etc", "profile-any"), "any\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs.x86_64", "etc", "profile-arch"), "arch\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs", "etc", "origin"), "profile-base\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs.any", "etc", "origin"), "profile-any\n")
	writeTestFile(t, filepath.Join(sourceDir, "airootfs.x86_64", "etc", "origin"), "profile-arch\n")

	writeTestFile(t, filepath.Join(moduleDir, "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 7,
		"arch": ["x86_64", "i686"],
		"load_scripts": ["load.sh"],
		"injects": {"post_hook": ["module_hook"]},
		"append_kernel_param": ["quiet", "quiet", "splash"]
	}`)
	writeTestFile(t, filepath.Join(moduleDir, "load.sh"), "#!/usr/bin/env bash\nmodule_marker=loaded\n")
	writeTestFile(t, filepath.Join(moduleDir, "packages.d", "base"), "a-module-base\nshared\n")
	writeTestFile(t, filepath.Join(moduleDir, "packages.any"), "b-module-any\n")
	writeTestFile(t, filepath.Join(moduleDir, "packages.x86_64.d", "arch"), "c-module-arch\n")
	writeTestFile(t, filepath.Join(moduleDir, "bootstrap_packages"), "module-bootstrap-base\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs", "etc", "module-base"), "base\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs.any", "etc", "module-any"), "any\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs.x86_64", "etc", "module-arch"), "arch\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs", "etc", "origin"), "module-base\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs.any", "etc", "origin"), "module-any\n")
	writeTestFile(t, filepath.Join(moduleDir, "airootfs.x86_64", "etc", "origin"), "module-arch\n")

	writeTestFile(
		t,
		filepath.Join(bootloadersDir, "syslinux", "syslinux.cfg"),
		"%ALTERISO_OS_NAME%|%ALTERISO_KERNEL_NAME%|%ALTERISO_COW_SPACESIZE%|%ALTERISO_KERNEL_PARAM%\n",
	)

	loaded, err := profile.Load(sourceDir, modulesDir)
	if err != nil {
		t.Fatalf("Loader.Load() error = %v", err)
	}
	err = Generate(loaded, outputDir, Options{
		BootloadersDir: bootloadersDir,
		NoConfirm:      true,
	})
	if err != nil {
		t.Fatalf("Generator.Generate() error = %v", err)
	}

	if got, want := readTestFile(t, filepath.Join(outputDir, "syslinux", "syslinux.cfg")),
		"Test Linux|linux-test|2G|quiet splash\n"; got != want {
		t.Errorf("bootloader config = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(outputDir, "packages.x86_64")),
		"a-module-base\nb-module-any\nc-module-arch\nd-profile-base\ne-profile-any\nf-profile-arch\nshared\n"; got != want {
		t.Errorf("packages.x86_64 = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(outputDir, "bootstrap_packages.x86_64")),
		"module-bootstrap-base\nprofile-bootstrap-any\n"; got != want {
		t.Errorf("bootstrap_packages.x86_64 = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(outputDir, "pacman.conf")), "profile-arch\n"; got != want {
		t.Errorf("pacman.conf = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(outputDir, "airootfs", "etc", "origin")), "profile-arch\n"; got != want {
		t.Errorf("airootfs overlay = %q, want %q", got, want)
	}
	for _, marker := range []string{
		"module-base",
		"module-any",
		"module-arch",
		"profile-base",
		"profile-any",
		"profile-arch",
	} {
		if _, err := os.Stat(filepath.Join(outputDir, "airootfs", "etc", marker)); err != nil {
			t.Errorf("airootfs layer %s is missing: %v", marker, err)
		}
	}

	renderedDefinition := readTestFile(t, filepath.Join(outputDir, "profiledef.sh"))
	for _, expected := range []string{"module_marker=loaded", "module_hook", "profile_hook"} {
		if !strings.Contains(renderedDefinition, expected) {
			t.Errorf("profiledef.sh does not contain %q", expected)
		}
	}
	for _, filename := range []string{
		"alteriso.json",
		"bootstrap_packages.x86_64",
		"injecter.sh",
		"pacman.conf",
		"profiledef.json",
	} {
		if _, err := os.Stat(filepath.Join(outputDir, filename)); err != nil {
			t.Errorf("generated file %s is missing: %v", filename, err)
		}
	}
	var metadata profileInfo
	if err := json.Unmarshal([]byte(readTestFile(t, filepath.Join(outputDir, "alteriso.json"))), &metadata); err != nil {
		t.Fatalf("failed to decode alteriso.json: %v", err)
	}
	if got, want := metadata.AlterISO, buildinfo.Current(); got != want {
		t.Errorf("alteriso binary metadata = %#v, want %#v", got, want)
	}

	i686OutputDir := filepath.Join(root, "output-i686")
	err = Generate(loaded, i686OutputDir, Options{
		BootloadersDir: bootloadersDir,
		Arch:           "i686",
	})
	if err != nil {
		t.Fatalf("Generator.Generate(i686) error = %v", err)
	}
	if _, err := os.Stat(filepath.Join(i686OutputDir, "packages.i686")); err != nil {
		t.Errorf("i686 package list is missing: %v", err)
	}
	if got, want := readTestFile(t, filepath.Join(i686OutputDir, "packages.i686")),
		"a-module-base\nb-module-any\nd-profile-base\ne-profile-any\nshared\n"; got != want {
		t.Errorf("packages.i686 = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(i686OutputDir, "pacman.conf")), "profile-any\n"; got != want {
		t.Errorf("i686 pacman.conf = %q, want %q", got, want)
	}
	if got, want := readTestFile(t, filepath.Join(i686OutputDir, "airootfs", "etc", "origin")), "profile-any\n"; got != want {
		t.Errorf("i686 airootfs overlay = %q, want %q", got, want)
	}
	if got := readTestFile(t, filepath.Join(i686OutputDir, "profiledef.json")); !strings.Contains(got, `"arch":"i686"`) {
		t.Errorf("i686 profiledef.json = %s", got)
	}
	if loaded.Definition.Arch != "x86_64" {
		t.Errorf("loaded profile architecture changed to %q", loaded.Definition.Arch)
	}
}

func TestPacmanConfPathSupportsAllArchitectureForms(t *testing.T) {
	tests := []struct {
		name       string
		pacmanConf string
		files      []string
		expected   string
	}{
		{
			name:     "unsuffixed fallback",
			files:    []string{"pacman.conf"},
			expected: "pacman.conf",
		},
		{
			name:     "any overrides unsuffixed",
			files:    []string{"pacman.conf", "pacman.conf.any"},
			expected: "pacman.conf.any",
		},
		{
			name:     "specific overrides any",
			files:    []string{"pacman.conf", "pacman.conf.any", "pacman.conf.x86_64"},
			expected: "pacman.conf.x86_64",
		},
		{
			name:       "configured base uses the same precedence",
			pacmanConf: "custom.conf",
			files:      []string{"custom.conf", "custom.conf.any", "custom.conf.x86_64"},
			expected:   "custom.conf.x86_64",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			profileDir := t.TempDir()
			for _, file := range test.files {
				writeTestFile(t, filepath.Join(profileDir, file), file+"\n")
			}
			loaded := &profile.Profile{
				Definition: profile.Definition{
					Arch:       "x86_64",
					PacmanConf: test.pacmanConf,
				},
				Dir: profileDir,
			}
			if got, want := pacmanConfPath(loaded), filepath.Join(profileDir, test.expected); got != want {
				t.Errorf("pacmanConfPath() = %q, want %q", got, want)
			}
		})
	}
}

func TestPrepareProfileReportsMissingInputs(t *testing.T) {
	loaded := &profile.Profile{
		Definition: profile.Definition{Arch: "x86_64"},
		Dir:        t.TempDir(),
	}
	_, err := prepareProfile(loaded, Options{BootloadersDir: filepath.Join(t.TempDir(), "missing")})
	if err == nil || !strings.Contains(err.Error(), "bootloaders directory") {
		t.Fatalf("prepareProfile() error = %v, want missing bootloaders directory", err)
	}
}

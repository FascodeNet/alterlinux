package profilegen

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func loadPackagesTestProfile(t *testing.T, root string) *profile.Profile {
	t.Helper()
	sourceDir := filepath.Join(root, "profile")
	modulesDir := filepath.Join(root, "modules")
	writeTestFile(t, filepath.Join(sourceDir, "profiledef.json"), `{"arch": "i486", "modules": ["example"]}`)
	writeTestFile(t, filepath.Join(modulesDir, "example", "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": "any"
	}`)
	loaded, err := profile.Load(sourceDir, modulesDir)
	if err != nil {
		t.Fatalf("Loader.Load() error = %v", err)
	}
	return loaded
}

func generateTestPackages(t *testing.T, root string) string {
	t.Helper()
	loaded := loadPackagesTestProfile(t, root)
	outDir := filepath.Join(root, "out")
	writeTestFile(t, filepath.Join(outDir, ".keep"), "")
	if err := generatePackageFiles(loaded, outDir); err != nil {
		t.Fatalf("generatePackageFiles() error = %v", err)
	}
	return readTestFile(t, filepath.Join(outDir, "packages.i486"))
}

func TestPackageExclusionRemovesEarlierLayers(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "packages"), "foo\nbar\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.any.d", "extra"), "qux\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.i486"), "!foo\n!qux\n")

	if got, want := generateTestPackages(t, root), "bar\n"; got != want {
		t.Errorf("packages.i486 = %q, want %q", got, want)
	}
}

func TestPackageExclusionAppliesToModulePackages(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "modules", "example", "packages"), "modpkg\nkept\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.i486"), "!modpkg\n")

	if got, want := generateTestPackages(t, root), "kept\n"; got != want {
		t.Errorf("packages.i486 = %q, want %q", got, want)
	}
}

func TestPackageExclusionWinsWithinSameLayer(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "packages.i486"), "archpkg\nkept\n")
	writeTestFile(t, filepath.Join(root, "modules", "example", "packages.i486.d", "drop"), "!archpkg\n")

	if got, want := generateTestPackages(t, root), "kept\n"; got != want {
		t.Errorf("packages.i486 = %q, want %q", got, want)
	}
}

func TestPackageLaterLayerReaddsExcluded(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "packages"), "foo\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.any"), "!foo\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.i486"), "foo\n")

	if got, want := generateTestPackages(t, root), "foo\n"; got != want {
		t.Errorf("packages.i486 = %q, want %q", got, want)
	}
}

func TestPackageExclusionOfAbsentPackageSucceeds(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "packages"), "foo\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages.i486"), "!missing\n")

	if got, want := generateTestPackages(t, root), "foo\n"; got != want {
		t.Errorf("packages.i486 = %q, want %q", got, want)
	}
}

func TestPackageEmptyExclusionFails(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "packages"), "foo\n!\n")

	loaded := loadPackagesTestProfile(t, root)
	outDir := filepath.Join(root, "out")
	writeTestFile(t, filepath.Join(outDir, ".keep"), "")
	if err := generatePackageFiles(loaded, outDir); err == nil {
		t.Fatal("generatePackageFiles() expected error for empty exclusion")
	}
}

func TestBootstrapPackageExclusion(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "bootstrap_packages"), "foo\nbar\n")
	writeTestFile(t, filepath.Join(root, "profile", "bootstrap_packages.i486"), "!bar\n")

	loaded := loadPackagesTestProfile(t, root)
	outDir := filepath.Join(root, "out")
	writeTestFile(t, filepath.Join(outDir, ".keep"), "")
	if err := generatePackageFiles(loaded, outDir); err != nil {
		t.Fatalf("generatePackageFiles() error = %v", err)
	}
	if got, want := readTestFile(t, filepath.Join(outDir, "bootstrap_packages.i486")), "foo\n"; got != want {
		t.Errorf("bootstrap_packages.i486 = %q, want %q", got, want)
	}
}

func TestAURPackageLayersUsePackageExclusions(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "profile", "profiledef.json"), `{"arch":"i486","modules":["example","aur"]}`)
	writeTestFile(t, filepath.Join(root, "modules", "aur", "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": "any"
	}`)
	writeTestFile(t, filepath.Join(root, "modules", "example", "alteriso.json"), `{
		"manifest_version": 1,
		"module_version": 1,
		"arch": "any"
	}`)
	writeTestFile(t, filepath.Join(root, "modules", "example", "packages_aur"), "module-aur\nremoved\n")
	writeTestFile(t, filepath.Join(root, "profile", "packages_aur.i486"), "!removed\nprofile-aur\n")

	loaded, err := profile.Load(filepath.Join(root, "profile"), filepath.Join(root, "modules"))
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	outDir := filepath.Join(root, "out")
	writeTestFile(t, filepath.Join(outDir, ".keep"), "")
	if err := generatePackageFiles(loaded, outDir); err != nil {
		t.Fatalf("generatePackageFiles() error = %v", err)
	}
	if got, want := readTestFile(t, filepath.Join(outDir, "packages_aur.i486")), "module-aur\nprofile-aur\n"; got != want {
		t.Errorf("packages_aur.i486 = %q, want %q", got, want)
	}
}

func TestAURPackageListRequiresAURModule(t *testing.T) {
	for _, test := range []struct {
		name string
		path string
	}{
		{name: "profile file", path: filepath.Join("profile", "packages_aur.i486")},
		{name: "module directory", path: filepath.Join("modules", "example", "packages_aur.any.d", "packages")},
		{name: "bootstrap profile file", path: filepath.Join("profile", "bootstrap_packages_aur.i486")},
	} {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			writeTestFile(t, filepath.Join(root, test.path), "aur-package\n")
			loaded := loadPackagesTestProfile(t, root)
			outDir := filepath.Join(root, "out")
			writeTestFile(t, filepath.Join(outDir, ".keep"), "")

			err := generatePackageFiles(loaded, outDir)
			base := "packages_aur"
			if strings.Contains(test.name, "bootstrap") {
				base = "bootstrap_packages_aur"
			}
			if err == nil || !strings.Contains(err.Error(), base+" requires the aur module") {
				t.Fatalf("generatePackageFiles() error = %v, want missing aur module error", err)
			}
		})
	}
}

func TestEmptyAURPackageListDoesNotRequireAURModule(t *testing.T) {
	for _, content := range []string{"", "\n# no packages\n", "!excluded\n"} {
		root := t.TempDir()
		writeTestFile(t, filepath.Join(root, "profile", "packages_aur.i486"), content)
		loaded := loadPackagesTestProfile(t, root)
		outDir := filepath.Join(root, "out")
		writeTestFile(t, filepath.Join(outDir, ".keep"), "")

		if err := generatePackageFiles(loaded, outDir); err != nil {
			t.Errorf("generatePackageFiles() with %q error = %v", content, err)
		}
	}
}

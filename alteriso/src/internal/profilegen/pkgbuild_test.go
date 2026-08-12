package profilegen

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func loadPkgbuildTestProfile(t *testing.T, root string) *profile.Profile {
	t.Helper()
	writeTestFile(t, filepath.Join(root, "profile", "profiledef.json"), `{"arch":"i486","modules":["example","aur"]}`)
	for _, name := range []string{"example", "aur"} {
		writeTestFile(t, filepath.Join(root, "modules", name, "alteriso.json"), `{"manifest_version":1,"module_version":1,"arch":"any"}`)
	}
	loaded, err := profile.Load(filepath.Join(root, "profile"), filepath.Join(root, "modules"))
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	return loaded
}

func TestCopyLocalPackageSourcesSelectsArchitectureLayers(t *testing.T) {
	root := t.TempDir()
	loaded := loadPkgbuildTestProfile(t, root)
	writeTestFile(t, filepath.Join(root, "modules", "example", "pkgbuild.any", "common", "PKGBUILD"), "pkgname=common\n")
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.i486", "specific", "PKGBUILD"), "pkgname=specific\n")
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.x86_64", "ignored", "PKGBUILD"), "pkgname=ignored\n")

	outDir := filepath.Join(root, "out")
	if err := copyLocalPackageSources(loaded, outDir); err != nil {
		t.Fatalf("copyLocalPackageSources() error = %v", err)
	}
	for _, name := range []string{"common", "specific"} {
		if _, err := os.Stat(filepath.Join(outDir, "pkgbuild", name, "PKGBUILD")); err != nil {
			t.Errorf("local package source %s is missing: %v", name, err)
		}
	}
	if _, err := os.Stat(filepath.Join(outDir, "pkgbuild", "ignored")); !os.IsNotExist(err) {
		t.Errorf("wrong-architecture package source was copied: %v", err)
	}
}

func TestCopyLocalPackageSourcesRejectsDuplicateNames(t *testing.T) {
	root := t.TempDir()
	loaded := loadPkgbuildTestProfile(t, root)
	writeTestFile(t, filepath.Join(root, "modules", "example", "pkgbuild.any", "duplicate", "PKGBUILD"), "pkgname=first\n")
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.i486", "duplicate", "PKGBUILD"), "pkgname=second\n")

	err := copyLocalPackageSources(loaded, filepath.Join(root, "out"))
	if err == nil || !strings.Contains(err.Error(), "defined by both") {
		t.Fatalf("copyLocalPackageSources() error = %v, want duplicate source error", err)
	}
}

func TestCopyLocalPackageSourcesOverlaysArchitectureWithinOneSource(t *testing.T) {
	root := t.TempDir()
	loaded := loadPkgbuildTestProfile(t, root)
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.any", "layered", "PKGBUILD"), "pkgname=common\n")
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.i486", "layered", "PKGBUILD"), "pkgname=i486\n")

	outDir := filepath.Join(root, "out")
	if err := copyLocalPackageSources(loaded, outDir); err != nil {
		t.Fatalf("copyLocalPackageSources() error = %v", err)
	}
	if got, want := readTestFile(t, filepath.Join(outDir, "pkgbuild", "layered", "PKGBUILD")), "pkgname=i486\n"; got != want {
		t.Errorf("layered PKGBUILD = %q, want %q", got, want)
	}
}

func TestCopyLocalPackageSourcesRequiresAURModule(t *testing.T) {
	root := t.TempDir()
	loaded := loadPackagesTestProfile(t, root)
	writeTestFile(t, filepath.Join(root, "profile", "pkgbuild.i486", "local", "PKGBUILD"), "pkgname=local\n")

	err := copyLocalPackageSources(loaded, filepath.Join(root, "out"))
	if err == nil || !strings.Contains(err.Error(), "require the aur module") {
		t.Fatalf("copyLocalPackageSources() error = %v, want missing aur module error", err)
	}
}

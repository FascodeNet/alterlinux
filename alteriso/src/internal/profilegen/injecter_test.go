package profilegen

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func writeInjecterAsset(t *testing.T, root string) string {
	t.Helper()

	content, err := readAsset("injecter.sh")
	if err != nil {
		t.Fatalf("failed to read embedded injecter: %v", err)
	}
	filename := filepath.Join(root, "injecter.sh")
	writeTestFile(t, filename, string(content))
	return filename
}

func runAlterisoMakeVersion(t *testing.T, injecter, profileDir, root, buildmode string) ([]byte, error) {
	t.Helper()

	command := exec.Command("bash", filepath.Join("testdata", "injecter", "make-version.sh"), injecter, profileDir, buildmode, root)
	return command.CombinedOutput()
}

func TestAlterisoMakeVersionPlacesMetadataByBuildmode(t *testing.T) {
	for _, buildmode := range []string{"iso", "netboot", "bootstrap"} {
		t.Run(buildmode, func(t *testing.T) {
			root := t.TempDir()
			profileDir := filepath.Join(root, "profile")
			injecter := writeInjecterAsset(t, root)
			writeTestFile(t, filepath.Join(profileDir, "alteriso.json"), "metadata\n")

			output, err := runAlterisoMakeVersion(t, injecter, profileDir, root, buildmode)
			if err != nil {
				t.Fatalf("__alteriso_make_version() error = %v\n%s", err, output)
			}

			pacstrapMetadata := filepath.Join(root, "pacstrap", "alteriso.json")
			isoMetadata := filepath.Join(root, "isofs", "alter", "alteriso.json")
			bootstrapMetadata := filepath.Join(root, "bootstrap", "alteriso.json")

			var expectedDestinations []string
			var absentDestinations []string
			switch buildmode {
			case "iso", "netboot":
				expectedDestinations = []string{pacstrapMetadata, isoMetadata}
				absentDestinations = []string{bootstrapMetadata}
			case "bootstrap":
				expectedDestinations = []string{bootstrapMetadata}
				absentDestinations = []string{pacstrapMetadata, isoMetadata}
			}

			if got, want := strings.TrimSpace(readTestFile(t, filepath.Join(root, "install.log"))),
				strings.Join(expectedDestinations, "\n"); got != want {
				t.Errorf("install destinations = %q, want %q", got, want)
			}
			for _, destination := range expectedDestinations {
				if got, want := readTestFile(t, destination), "metadata\n"; got != want {
					t.Errorf("%s = %q, want %q", destination, got, want)
				}
			}
			for _, destination := range absentDestinations {
				if _, err := os.Stat(destination); !os.IsNotExist(err) {
					t.Errorf("unexpected metadata at %s: %v", destination, err)
				}
			}
		})
	}
}

func TestAlterisoMakeVersionSkipsMissingMetadata(t *testing.T) {
	for _, buildmode := range []string{"iso", "netboot", "bootstrap"} {
		t.Run(buildmode, func(t *testing.T) {
			root := t.TempDir()
			injecter := writeInjecterAsset(t, root)
			profileDir := filepath.Join(root, "profile")
			if err := os.MkdirAll(profileDir, 0o755); err != nil {
				t.Fatalf("failed to create profile directory: %v", err)
			}

			output, err := runAlterisoMakeVersion(t, injecter, profileDir, root, buildmode)
			if err != nil {
				t.Fatalf("__alteriso_make_version() error = %v\n%s", err, output)
			}
			if _, err := os.Stat(filepath.Join(root, "install.log")); !os.IsNotExist(err) {
				t.Errorf("__alteriso_make_version() attempted to install missing metadata: %v", err)
			}
		})
	}
}

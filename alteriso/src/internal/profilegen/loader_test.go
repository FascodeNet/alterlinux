package profilegen

import (
	"os/exec"
	"path/filepath"
	"testing"
)

func TestAlterisoArchPrefersRuntimeArchitecture(t *testing.T) {
	content, err := readAsset("loader.sh")
	if err != nil {
		t.Fatalf("readAsset(loader.sh) error = %v", err)
	}
	loader := writeTestFileContent(t, string(content))

	output, err := exec.Command("bash", filepath.Join("testdata", "loader", "architecture.sh"), loader).CombinedOutput()
	if err != nil {
		t.Fatalf("__alteriso_arch error = %v\n%s", err, output)
	}
	if got, want := string(output), "i486\nx86_64\n"; got != want {
		t.Errorf("__alteriso_arch output = %q, want %q", got, want)
	}
}

func writeTestFileContent(t *testing.T, content string) string {
	t.Helper()
	filename := filepath.Join(t.TempDir(), "loader.sh")
	writeTestFile(t, filename, content)
	return filename
}

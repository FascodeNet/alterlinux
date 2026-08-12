package profilegen

import (
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"
)

func TestAddValidatorIgnoresDuplicateRegistration(t *testing.T) {
	content, err := readAsset("loader.sh")
	if err != nil {
		t.Fatalf("readAsset(loader.sh) error = %v", err)
	}
	loader := filepath.Join(t.TempDir(), "loader.sh")
	writeTestFile(t, loader, string(content))
	output, err := exec.Command("bash", filepath.Join("testdata", "validator", "duplicates.sh"), loader).CombinedOutput()
	if err != nil {
		t.Fatalf("__alteriso_add_validator error = %v\n%s", err, output)
	}
	if got, want := string(output), "first\nsecond\n"; got != want {
		t.Errorf("validators = %q, want %q", got, want)
	}
}

func TestModulesValidateRequiredProfileValues(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	modulesDir := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules"))
	for _, module := range []string{"base", "live-user", "gdm", "lightdm", "alter-calamares"} {
		t.Run(module, func(t *testing.T) {
			script := filepath.Join(modulesDir, module, "module.sh")
			output, err := exec.Command("bash", filepath.Join("testdata", "validator", "required-value.sh"), script).CombinedOutput()
			if err == nil {
				t.Fatalf("%s accepted an empty required profile value\n%s", module, output)
			}
		})
	}
}

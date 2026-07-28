// LLM Generated: Created by Claude
package profilegen

import (
	"flag"
	"os"
	"path/filepath"
	"runtime"
	"slices"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/samber/lo"
)

var updateGolden = flag.Bool("update", false, "rewrite the golden package lists")

func projectDir(t *testing.T) string {
	t.Helper()

	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", ".."))
}

// TestPackageListsMatchGolden makes a variant that stopped applying show up as
// a diff in review, rather than only after an ISO is built.
func TestPackageListsMatchGolden(t *testing.T) {
	project := projectDir(t)
	configsDir := filepath.Join(project, "configs")
	modulesDir := filepath.Join(project, "modules")
	goldenDir := filepath.Join(project, "tests", "golden")

	entries, err := os.ReadDir(configsDir)
	if err != nil {
		t.Fatalf("failed to read configs: %v", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		configDir := filepath.Join(configsDir, entry.Name())
		base, err := profile.Load(configDir, modulesDir, nil)
		if err != nil {
			t.Fatalf("profile.Load(%s) error = %v", entry.Name(), err)
		}
		available, err := base.AvailableVariants()
		if err != nil {
			t.Fatalf("AvailableVariants(%s) error = %v", entry.Name(), err)
		}

		names := slices.Sorted(slices.Values(lo.Keys(available)))
		selections := append([][]string{nil}, lo.Map(
			names,
			func(variant string, _ int) []string { return []string{variant} },
		)...)
		// 単体だけでは、複数選択したときの上書きと除外の相互作用が検証されない
		if len(names) > 1 {
			selections = append(selections, names)
		}
		for _, variants := range selections {
			name := entry.Name()
			if len(variants) > 0 {
				name += "+" + strings.Join(variants, "+")
			}
			t.Run(name, func(t *testing.T) {
				comparePackageListWithGolden(t, configDir, modulesDir, project, goldenDir, name, variants)
			})
		}
	}
}

func comparePackageListWithGolden(t *testing.T, configDir, modulesDir, project, goldenDir, name string, variants []string) {
	t.Helper()

	loaded, err := profile.Load(configDir, modulesDir, variants)
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	outputDir := filepath.Join(t.TempDir(), "generated")
	options := Options{BootloadersDir: filepath.Join(project, "bootloaders"), NoConfirm: true}
	if err := Generate(loaded, outputDir, options); err != nil {
		t.Fatalf("Generate() error = %v", err)
	}

	filename := "packages." + loaded.Definition.Arch
	generated := readTestFile(t, filepath.Join(outputDir, filename))
	goldenPath := filepath.Join(goldenDir, name+"."+filename)

	if *updateGolden {
		writeTestFile(t, goldenPath, generated)
		return
	}
	expected, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("failed to read the golden package list (run go test ./... -update): %v", err)
	}
	if generated != string(expected) {
		t.Errorf("package list changed for %s; review the diff and run go test ./... -update", name)
	}
}

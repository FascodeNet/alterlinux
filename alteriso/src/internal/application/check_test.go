// LLM Generated: Created by Claude
package application

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

type recordingResolver struct {
	synced   []string
	resolved [][]string
	syncErr  error
	err      error
}

func (r *recordingResolver) Sync(configPath, dbPath string) error {
	r.synced = append(r.synced, configPath)
	return r.syncErr
}

func (r *recordingResolver) Resolve(configPath, dbPath string, packages []string) error {
	r.resolved = append(r.resolved, packages)
	return r.err
}

// checkService wires a service whose generator only writes the package list the
// check reads back, so the test stays independent of profilegen's other output.
func checkService(t *testing.T, resolver *recordingResolver, packageList string) *ProfileService {
	t.Helper()

	return &ProfileService{
		loadProfile: func(dir, modules string, variants []string) (*profile.Profile, error) {
			return profile.Load(dir, modules, variants)
		},
		generateProfile: func(loaded *profile.Profile, outDir string, _ profilegen.Options) error {
			if err := os.MkdirAll(outDir, 0o755); err != nil {
				return err
			}
			name := filepath.Join(outDir, "packages."+loaded.Definition.Arch)
			if err := os.WriteFile(name, []byte(packageList), 0o644); err != nil {
				return err
			}
			return os.WriteFile(filepath.Join(outDir, "pacman.conf"), []byte("[options]\n"), 0o644)
		},
		resolver: resolver,
	}
}

func writeCheckProfile(t *testing.T, root, name string, variants []string) string {
	t.Helper()

	dir := filepath.Join(root, "configs", name)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("failed to create profile directory: %v", err)
	}
	definition := `{"arch": "x86_64", "modules": []}`
	if err := os.WriteFile(filepath.Join(dir, "profiledef.json"), []byte(definition), 0o644); err != nil {
		t.Fatalf("failed to write profiledef.json: %v", err)
	}
	for _, variant := range variants {
		variantDir := filepath.Join(dir, "variants", variant)
		if err := os.MkdirAll(variantDir, 0o755); err != nil {
			t.Fatalf("failed to create variant directory: %v", err)
		}
	}
	return dir
}

func TestCheckCoversEveryVariantSelection(t *testing.T) {
	root := t.TempDir()
	writeCheckProfile(t, root, "xfce", []string{"japanese", "nvidia"})
	resolver := &recordingResolver{}

	reports, err := checkService(t, resolver, "base\nfcitx5\n").Check(CheckInput{
		ConfigsDir: filepath.Join(root, "configs"),
		ModulesDir: filepath.Join(root, "modules"),
	})
	if err != nil {
		t.Fatalf("Check() error = %v", err)
	}

	var labels []string
	for _, report := range reports {
		if !report.OK() {
			t.Errorf("check %s failed: %v", report.Label(), report.Err)
		}
		labels = append(labels, report.Label())
	}
	// 単体に加えて全部同時も見ないと、variant 同士の相互作用が検証されない
	want := []string{"xfce", "xfce +japanese", "xfce +nvidia", "xfce +japanese,nvidia"}
	if !reflect.DeepEqual(labels, want) {
		t.Errorf("checked selections = %v, want %v", labels, want)
	}
	if got, want := resolver.resolved[0], []string{"base", "fcitx5"}; !reflect.DeepEqual(got, want) {
		t.Errorf("resolved packages = %v, want %v", got, want)
	}
}

func TestCheckFailsOnEmptyPackageList(t *testing.T) {
	root := t.TempDir()
	writeCheckProfile(t, root, "minimum", nil)

	reports, err := checkService(t, &recordingResolver{}, "# only a comment\n").Check(CheckInput{
		ConfigsDir: filepath.Join(root, "configs"),
		ModulesDir: filepath.Join(root, "modules"),
	})
	if err != nil {
		t.Fatalf("Check() error = %v", err)
	}
	if len(reports) != 1 {
		t.Fatalf("got %d reports, want 1", len(reports))
	}
	if reports[0].OK() {
		t.Fatal("check passed on an empty package list")
	}
	if !strings.Contains(reports[0].Err.Error(), "package list is empty") {
		t.Errorf("error = %q, want it to name the empty package list", reports[0].Err)
	}
}

func TestCheckSeparatesSyncFailureFromResolveFailure(t *testing.T) {
	root := t.TempDir()
	writeCheckProfile(t, root, "xfce", nil)
	resolver := &recordingResolver{syncErr: os.ErrDeadlineExceeded}

	reports, err := checkService(t, resolver, "base\n").Check(CheckInput{
		ConfigsDir: filepath.Join(root, "configs"),
		ModulesDir: filepath.Join(root, "modules"),
	})
	if err != nil {
		t.Fatalf("Check() error = %v", err)
	}
	if reports[0].OK() {
		t.Fatal("check passed despite a failed sync")
	}
	if !strings.Contains(reports[0].Err.Error(), "mirror or network") {
		t.Errorf("error = %q, want it to blame the mirror, not the package list", reports[0].Err)
	}
	if len(resolver.resolved) != 0 {
		t.Error("resolve ran even though the sync failed")
	}
}

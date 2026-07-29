// LLM Generated: Created by Claude
package application

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

func requirePacman(t *testing.T) {
	t.Helper()

	if _, err := exec.LookPath("pacman"); err != nil {
		t.Skip("pacman is not installed")
	}
}

// checkService builds a service whose generator writes only what the check
// reads back, so a test can hand pacman a chosen configuration.
func checkService(packageList, pacmanConf string) *ProfileService {
	return &ProfileService{
		loadProfile: profile.Load,
		generateProfile: func(loaded *profile.Profile, outDir string, _ profilegen.Options) error {
			if err := os.MkdirAll(outDir, 0o755); err != nil {
				return err
			}
			name := filepath.Join(outDir, "packages."+loaded.Definition.Arch)
			if err := os.WriteFile(name, []byte(packageList), 0o644); err != nil {
				return err
			}
			return os.WriteFile(filepath.Join(outDir, "pacman.conf"), []byte(pacmanConf), 0o644)
		},
	}
}

func writeTestProfile(t *testing.T, root string) string {
	t.Helper()

	dir := filepath.Join(root, "configs", "example")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("failed to create the profile directory: %v", err)
	}
	definition := `{"arch": "x86_64", "modules": []}`
	if err := os.WriteFile(filepath.Join(dir, "profiledef.json"), []byte(definition), 0o644); err != nil {
		t.Fatalf("failed to write profiledef.json: %v", err)
	}
	return filepath.Join(root, "configs")
}

func TestVariantSelectionsCoverEachVariantAndAllTogether(t *testing.T) {
	tests := []struct {
		name      string
		available map[string][]string
		want      [][]string
	}{
		{
			name:      "no variants",
			available: nil,
			want:      [][]string{nil},
		},
		{
			name:      "one variant",
			available: map[string][]string{"japanese": {"xfce"}},
			want:      [][]string{nil, {"japanese"}},
		},
		{
			// 単体だけでは、複数選んだときの上書きと除外の相互作用が検証されない
			name:      "several variants add the combined selection",
			available: map[string][]string{"nvidia": {"xfce"}, "japanese": {"fonts", "xfce"}},
			want:      [][]string{nil, {"japanese"}, {"nvidia"}, {"japanese", "nvidia"}},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := variantSelections(tt.available); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("variantSelections() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestReadPackageListDropsCommentsAndBlanks(t *testing.T) {
	filename := filepath.Join(t.TempDir(), "packages.x86_64")
	content := "# comment\n\n  base  \nfcitx5-mozc\n"
	if err := os.WriteFile(filename, []byte(content), 0o644); err != nil {
		t.Fatalf("failed to write the package list: %v", err)
	}

	got, err := readPackageList(filename)
	if err != nil {
		t.Fatalf("readPackageList() error = %v", err)
	}
	if want := []string{"base", "fcitx5-mozc"}; !reflect.DeepEqual(got, want) {
		t.Errorf("readPackageList() = %v, want %v", got, want)
	}
}

// TestCheckFailsOnEmptyPackageList pins the guard that has to live outside the
// pacman call: pacman syncs and exits 0 when it is given no targets.
func TestCheckFailsOnEmptyPackageList(t *testing.T) {
	root := t.TempDir()
	configsDir := writeTestProfile(t, root)

	reports, err := checkService("# only a comment\n", "[options]\n").Check(CheckInput{
		ConfigsDir: configsDir,
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
	if got := reports[0].Err.Error(); got != "package list is empty" {
		t.Errorf("error = %q, want %q", got, "package list is empty")
	}
}

func TestRunPacmanIncludesTheCommandOutput(t *testing.T) {
	requirePacman(t)

	// -Q はローカルデータベースを読むだけなので root を必要としない
	err := runPacman("-Qi", "definitely-not-installed-xyz-123")
	if err == nil {
		t.Fatal("runPacman() succeeded for a package that cannot exist")
	}
	for _, want := range []string{"pacman -Qi", "definitely-not-installed-xyz-123"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error = %q, want it to contain %q", err, want)
		}
	}
}

// TestCheckLabelsSyncFailure keeps a failing sync from being reported as a
// broken package list. The repository is unreachable on purpose.
func TestCheckLabelsSyncFailure(t *testing.T) {
	requirePacman(t)

	root := t.TempDir()
	configsDir := writeTestProfile(t, root)
	pacmanConf := "[options]\nArchitecture = x86_64\nSigLevel = Never\n\n" +
		"[unreachable]\nServer = http://127.0.0.1:1/$repo/os/$arch\n"

	reports, err := checkService("base\n", pacmanConf).Check(CheckInput{
		ConfigsDir: configsDir,
		ModulesDir: filepath.Join(root, "modules"),
	})
	if err != nil {
		t.Fatalf("Check() error = %v", err)
	}
	if len(reports) != 1 || reports[0].OK() {
		t.Fatalf("reports = %+v, want a single failure", reports)
	}
	message := reports[0].Err.Error()
	if !strings.Contains(message, "repository sync") || !strings.Contains(message, "mirror or network") {
		t.Errorf("error = %q, want it to blame the repository sync", message)
	}
	if strings.Contains(message, "pacman -Sp") {
		t.Errorf("error = %q, want the resolve step to be skipped after a failed sync", message)
	}
}

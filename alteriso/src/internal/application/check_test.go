// LLM Generated: Created by Claude
package application

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

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
	configDir := filepath.Join(root, "configs", "minimum")
	if err := os.MkdirAll(configDir, 0o755); err != nil {
		t.Fatalf("failed to create the profile directory: %v", err)
	}
	definition := `{"arch": "x86_64", "modules": []}`
	if err := os.WriteFile(filepath.Join(configDir, "profiledef.json"), []byte(definition), 0o644); err != nil {
		t.Fatalf("failed to write profiledef.json: %v", err)
	}

	service := &ProfileService{
		loadProfile: profile.Load,
		generateProfile: func(loaded *profile.Profile, outDir string, _ profilegen.Options) error {
			if err := os.MkdirAll(outDir, 0o755); err != nil {
				return err
			}
			name := filepath.Join(outDir, "packages."+loaded.Definition.Arch)
			return os.WriteFile(name, []byte("# only a comment\n"), 0o644)
		},
	}

	reports, err := service.Check(CheckInput{
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
	if got := reports[0].Err.Error(); got != "package list is empty" {
		t.Errorf("error = %q, want %q", got, "package list is empty")
	}
}

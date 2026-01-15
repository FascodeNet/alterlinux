package injectable

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/logger"
	"github.com/spf13/cobra"
)

//go:embed profile
var emptyProfile embed.FS

func extractEmptyProfile(dest string) error {
	return fs.WalkDir(emptyProfile, "profile", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel("profile", p)
		if err != nil {
			return err
		}

		destPath := filepath.Join(dest, relPath)

		if d.IsDir() {
			return os.MkdirAll(path.Join(dest, relPath), 0755)
		}

		data, err := emptyProfile.ReadFile(p)
		if err != nil {
			return err
		}

		return os.WriteFile(destPath, data, 0644)
	})

}

func TestInjectable() (bool, error) {
	tmpdir, err := os.MkdirTemp("", "alteriso-injectable-test-")
	if err != nil {
		return false, err
	}
	defer os.RemoveAll(tmpdir)

	alterisoProfileDir := path.Join(tmpdir, "alteriso")
	archisoProfileDir := path.Join(tmpdir, "archiso")

	if err := extractEmptyProfile(alterisoProfileDir); err != nil {
		return false, errors.Wrap(err)
	}

	// slog.Info("Loading alteriso profile", "dir", archisoProfileDir)
	profile, err := archiso.NewProfile(alterisoProfileDir, archiso.WithModulesPath(""), archiso.WithbootloadersPath(alterisoProfileDir))
	if err != nil {
		return false, errors.Wrap(err)
	}

	// slog.Info("Generating archiso profile", "dir", archisoProfileDir)

	err = logger.WithoutLog(func() error {
		return profile.GenArchisoProfile(archisoProfileDir)
	})
	if err != nil {
		return false, errors.Wrap(err)
	}

	// slog.Info("Testing injectable", "dir", archisoProfileDir)
	testCmd := exec.Command("fakeroot", "mkarchiso", "-v", archisoProfileDir)
	if err := testCmd.Run(); err != nil {
		return false, nil
	}

	return true, nil
}

func Cmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "test-injectable",
		Short: "Test if archiso is injectable",
		RunE: func(cmd *cobra.Command, args []string) error {
			injectable, err := TestInjectable()
			if err != nil {
				return err
			}
			if !injectable {
				fmt.Println("archiso is not injectable")
				return nil
			}

			fmt.Println("archiso is injectable")

			return nil
		},
	}
	return cmd
}

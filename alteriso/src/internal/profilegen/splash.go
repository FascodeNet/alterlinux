package profilegen

import (
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	cp "github.com/otiai10/copy"
)

func copySplashImage(loaded *profile.Profile, outDir string) error {
	source := filepath.Join(loaded.Dir, "splash.png")
	if !pathExists(source, regularFile) {
		return nil
	}

	destination := filepath.Join(outDir, "syslinux", "splash.png")
	if err := os.Remove(destination); err != nil && !os.IsNotExist(err) {
		return errors.Newf("failed to remove existing splash image: %w", err)
	}
	if err := cp.Copy(source, destination); err != nil {
		return errors.Newf("failed to copy splash image: %w", err)
	}
	return nil
}

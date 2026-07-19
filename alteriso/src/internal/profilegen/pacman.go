package profilegen

import (
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/Hayao0819/nahi/cputils"
)

func pacmanConfPath(loaded *profile.Profile) string {
	definition := loaded.Definition
	if definition.PacmanConf != "" {
		base := definition.PacmanConf
		if !filepath.IsAbs(base) {
			base = filepath.Join(loaded.Dir, base)
		}
		return preferredArchitectureFile(base, definition.Arch)
	}

	return preferredArchitectureFile(filepath.Join(loaded.Dir, "pacman.conf"), definition.Arch)
}

func preferredArchitectureFile(base, architecture string) string {
	layers := architectureLayers(base, architecture)
	for index := len(layers) - 1; index > 0; index-- {
		if pathExists(layers[index], regularFile) {
			return layers[index]
		}
	}
	return base
}

func copyPacmanConf(loaded *profile.Profile, outDir string) error {
	source := pacmanConfPath(loaded)
	destination := filepath.Join(outDir, "pacman.conf")
	if err := cputils.CopyAll(cputils.CopyTask{
		Source: source,
		Dest:   destination,
	}); err != nil {
		return errors.Newf("failed to copy %s to %s: %w", source, destination, err)
	}
	return nil
}

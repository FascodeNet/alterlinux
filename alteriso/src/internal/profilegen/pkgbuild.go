package profilegen

import (
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	cp "github.com/otiai10/copy"
	"github.com/samber/lo"
)

func copyLocalPackageSources(loaded *profile.Profile, outDir string) error {
	sourceDirs := make([]string, 0, len(loaded.Modules())+1)
	for _, module := range loaded.Modules() {
		sourceDirs = append(sourceDirs, module.Dir)
	}
	sourceDirs = append(sourceDirs, loaded.Dir)

	destinationRoot := filepath.Join(outDir, "pkgbuild")
	copied := map[string]string{}
	found := false
	for _, sourceDir := range sourceDirs {
		for _, layer := range architectureLayers(filepath.Join(sourceDir, "pkgbuild"), loaded.Definition.Arch) {
			entries, err := os.ReadDir(layer)
			if os.IsNotExist(err) {
				continue
			}
			if err != nil {
				return errors.Newf("failed to read local package directory %s: %w", layer, err)
			}
			for _, entry := range entries {
				if !entry.IsDir() {
					continue
				}
				source := filepath.Join(layer, entry.Name())
				if !pathExists(filepath.Join(source, "PKGBUILD"), regularFile) {
					continue
				}
				found = true
				if previous, exists := copied[entry.Name()]; exists && previous != sourceDir {
					return errors.Newf("local package source %s is defined by both %s and %s", entry.Name(), previous, source)
				}
				destination := filepath.Join(destinationRoot, entry.Name())
				if err := cp.Copy(source, destination); err != nil {
					return errors.Newf("failed to copy local package source %s: %w", source, err)
				}
				copied[entry.Name()] = sourceDir
			}
		}
	}
	if found && !lo.ContainsBy(loaded.Modules(), func(module profile.Module) bool { return module.Name == "aur" }) {
		return errors.New("local PKGBUILD sources require the aur module")
	}
	return nil
}

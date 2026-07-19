package profilegen

import (
	"log/slog"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	cp "github.com/otiai10/copy"
)

func copyAirootfs(loaded *profile.Profile, outDir string) error {
	destination := filepath.Join(outDir, "airootfs")
	var sources []string
	for _, module := range loaded.Modules() {
		sources = append(
			sources,
			architectureLayers(filepath.Join(module.Dir, "airootfs"), loaded.Definition.Arch)...,
		)
	}
	sources = append(
		sources,
		architectureLayers(filepath.Join(loaded.Dir, "airootfs"), loaded.Definition.Arch)...,
	)

	slog.Info("Copying airootfs", "dest", destination)
	for _, source := range sources {
		if !pathExists(source, directory) {
			slog.Debug("Skipping absent airootfs directory", "source", source)
			continue
		}
		slog.Info("Copying airootfs", "source", source, "dest", destination)
		if err := cp.Copy(source, destination); err != nil {
			// Preserve the existing best-effort behavior for optional overlays.
			slog.Warn("Failed to copy airootfs", "source", source, "dest", destination, "error", errors.Wrap(err))
		}
	}
	return nil
}

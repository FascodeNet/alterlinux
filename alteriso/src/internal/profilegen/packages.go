package profilegen

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func packageList(loaded *profile.Profile, filename string) ([]string, error) {
	sourceDirs := []string{loaded.Dir}
	for _, module := range loaded.Modules() {
		sourceDirs = append(sourceDirs, module.Dir)
	}

	var files []string
	for _, dir := range sourceDirs {
		file := filepath.Join(dir, filename)
		if entries, err := os.ReadDir(file + ".d"); err == nil {
			for _, entry := range entries {
				if !entry.IsDir() {
					files = append(files, filepath.Join(file+".d", entry.Name()))
				}
			}
		} else if !os.IsNotExist(err) {
			return nil, errors.Newf("failed to read package list directory %s: %w", file+".d", err)
		}
		files = append(files, file)
	}

	var packages []string
	for _, filename := range files {
		content, err := os.ReadFile(filename)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			return nil, errors.Newf("failed to read package list %s: %w", filename, err)
		}
		slog.Info("Loading packages file", "file", filename)
		for _, line := range strings.Split(string(content), "\n") {
			item := strings.TrimSpace(line)
			if item == "" || strings.HasPrefix(item, "#") {
				continue
			}
			packages = append(packages, item)
		}
	}
	return sortedUniqueStrings(packages), nil
}

func generatePackageFiles(loaded *profile.Profile, outDir string) error {
	architecture := loaded.Definition.Arch
	for _, base := range []string{"packages", "bootstrap_packages"} {
		var packages []string
		for _, filename := range architectureLayers(base, architecture) {
			layer, err := packageList(loaded, filename)
			if err != nil {
				return errors.Wrap(err)
			}
			packages = append(packages, layer...)
		}

		packages = sortedUniqueStrings(packages)
		content := strings.Join(packages, "\n") + "\n"
		destination := filepath.Join(outDir, base+"."+architecture)
		if err := os.WriteFile(destination, []byte(content), 0o644); err != nil {
			return errors.Newf("failed to write package list %s: %w", destination, err)
		}
	}
	return nil
}

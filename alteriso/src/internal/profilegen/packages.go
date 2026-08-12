package profilegen

import (
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/samber/lo"
)

// LLM Modified: Support '!' exclusion entries in package lists - Claude
type packageLayer struct {
	additions  []string
	exclusions []string
}

func isExclusion(item string, _ int) bool {
	return strings.HasPrefix(item, "!")
}

func packageListFiles(loaded *profile.Profile, filename string) ([]string, error) {
	sourceDirs := append(
		[]string{loaded.Dir},
		lo.Map(loaded.Modules(), func(module profile.Module, _ int) string { return module.Dir })...,
	)

	var files []string
	for _, dir := range sourceDirs {
		file := filepath.Join(dir, filename)
		entries, err := os.ReadDir(file + ".d")
		if err != nil && !os.IsNotExist(err) {
			return nil, errors.Newf("failed to read package list directory %s: %w", file+".d", err)
		}
		files = append(files, lo.FilterMap(entries, func(entry os.DirEntry, _ int) (string, bool) {
			return filepath.Join(file+".d", entry.Name()), !entry.IsDir()
		})...)
		files = append(files, file)
	}
	return files, nil
}

func packageList(loaded *profile.Profile, filename string) (packageLayer, error) {
	files, err := packageListFiles(loaded, filename)
	if err != nil {
		return packageLayer{}, err
	}

	var layer packageLayer
	for _, file := range files {
		content, err := os.ReadFile(file)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			return packageLayer{}, errors.Newf("failed to read package list %s: %w", file, err)
		}
		slog.Info("Loading packages file", "file", file)

		items := lo.FilterMap(strings.Split(string(content), "\n"), func(line string, _ int) (string, bool) {
			item := strings.TrimSpace(line)
			return item, item != "" && !strings.HasPrefix(item, "#")
		})
		exclusions := lo.Map(lo.Filter(items, isExclusion), func(item string, _ int) string {
			return strings.TrimSpace(strings.TrimPrefix(item, "!"))
		})
		if lo.Contains(exclusions, "") {
			return packageLayer{}, errors.Newf("invalid empty package exclusion in %s", file)
		}
		layer.additions = append(layer.additions, lo.Reject(items, isExclusion)...)
		layer.exclusions = append(layer.exclusions, exclusions...)
	}
	return layer, nil
}

func generatePackageFiles(loaded *profile.Profile, outDir string) error {
	architecture := loaded.Definition.Arch
	for _, base := range []string{"packages_aur", "bootstrap_packages_aur"} {
		configured, err := packageListConfigured(loaded, base, architecture)
		if err != nil {
			return errors.Wrap(err)
		}
		if configured && !lo.ContainsBy(loaded.Modules(), func(module profile.Module) bool { return module.Name == "aur" }) {
			return errors.Newf("%s requires the aur module", base)
		}
	}

	for _, base := range []string{"packages", "bootstrap_packages", "packages_aur", "bootstrap_packages_aur"} {
		var selected []string
		for _, filename := range architectureLayers(base, architecture) {
			layer, err := packageList(loaded, filename)
			if err != nil {
				return errors.Wrap(err)
			}
			// Within a layer exclusions win, so source order stays irrelevant.
			withAdditions := lo.Union(selected, layer.additions)
			for _, name := range lo.Without(layer.exclusions, withAdditions...) {
				slog.Warn("Excluded package is not in the list", "package", name, "layer", filename)
			}
			selected = lo.Without(withAdditions, layer.exclusions...)
		}

		slices.Sort(selected)
		content := strings.Join(selected, "\n") + "\n"
		destination := filepath.Join(outDir, base+"."+architecture)
		if err := os.WriteFile(destination, []byte(content), 0o644); err != nil {
			return errors.Newf("failed to write package list %s: %w", destination, err)
		}
	}
	return nil
}

func packageListConfigured(loaded *profile.Profile, base, architecture string) (bool, error) {
	var selected []string
	for _, layer := range architectureLayers(base, architecture) {
		packages, err := packageList(loaded, layer)
		if err != nil {
			return false, err
		}
		selected = lo.Without(lo.Union(selected, packages.additions), packages.exclusions...)
	}
	return len(selected) > 0, nil
}

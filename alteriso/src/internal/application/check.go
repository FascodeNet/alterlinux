// LLM Generated: Created by Claude
package application

import (
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
	"github.com/samber/lo"
)

// CheckInput selects what to check. Dirs wins over ConfigsDir when both are set.
type CheckInput struct {
	Dirs       []string
	ConfigsDir string
	ModulesDir string
	Generation profilegen.Options
}

// CheckReport is the outcome for one profile and variant selection.
type CheckReport struct {
	Config   string
	Variants []string
	Err      error
}

func (r CheckReport) Label() string {
	if len(r.Variants) == 0 {
		return r.Config
	}
	return r.Config + " +" + strings.Join(r.Variants, ",")
}

func (r CheckReport) OK() bool {
	return r.Err == nil
}

func (i CheckInput) configDirs() ([]string, error) {
	if len(i.Dirs) > 0 {
		return i.Dirs, nil
	}
	if i.ConfigsDir == "" {
		return nil, errors.New("no profile directory given")
	}
	entries, err := os.ReadDir(i.ConfigsDir)
	if err != nil {
		return nil, errors.Newf("failed to read profile directory %s: %w", i.ConfigsDir, err)
	}
	dirs := lo.FilterMap(entries, func(entry os.DirEntry, _ int) (string, bool) {
		return filepath.Join(i.ConfigsDir, entry.Name()), entry.IsDir()
	})
	if len(dirs) == 0 {
		return nil, errors.Newf("no profiles found in %s", i.ConfigsDir)
	}
	return dirs, nil
}

// variantSelections returns the selections to check: no variant, each variant
// on its own, and every variant together so their interaction is covered.
func variantSelections(available map[string][]string) [][]string {
	names := slices.Sorted(slices.Values(lo.Keys(available)))
	selections := append([][]string{nil}, lo.Map(names, func(name string, _ int) []string {
		return []string{name}
	})...)
	if len(names) > 1 {
		selections = append(selections, names)
	}
	return selections
}

// Check generates every profile and variant selection and verifies that the
// resulting package list resolves. It reports each outcome instead of stopping
// at the first failure.
func (s *ProfileService) Check(input CheckInput) ([]CheckReport, error) {
	dirs, err := input.configDirs()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	var reports []CheckReport
	for _, dir := range dirs {
		base, err := s.loadProfile(dir, input.ModulesDir, nil)
		if err != nil {
			reports = append(reports, CheckReport{Config: filepath.Base(dir), Err: errors.Wrap(err)})
			continue
		}
		available, err := base.AvailableVariants()
		if err != nil {
			reports = append(reports, CheckReport{Config: filepath.Base(dir), Err: errors.Wrap(err)})
			continue
		}
		for _, variants := range variantSelections(available) {
			report := CheckReport{Config: filepath.Base(dir), Variants: variants}
			report.Err = s.checkOne(dir, input, variants)
			slog.Info("Checked profile", "profile", report.Label(), "ok", report.OK())
			reports = append(reports, report)
		}
	}
	return reports, nil
}

func (s *ProfileService) checkOne(dir string, input CheckInput, variants []string) error {
	loaded, err := s.loadProfile(dir, input.ModulesDir, variants)
	if err != nil {
		return errors.Wrap(err)
	}

	workDir, err := os.MkdirTemp("", "alteriso-check-*")
	if err != nil {
		return errors.Newf("failed to create check directory: %w", err)
	}
	defer func() {
		_ = os.RemoveAll(workDir)
	}()

	generated := filepath.Join(workDir, "profile")
	generation := input.Generation
	generation.NoConfirm = true
	if err := s.generateProfile(loaded, generated, generation); err != nil {
		return errors.Newf("generate: %w", err)
	}

	architecture := loaded.Definition.Arch
	if generation.Arch != "" {
		architecture = generation.Arch
	}
	packages, err := readPackageList(filepath.Join(generated, "packages."+architecture))
	if err != nil {
		return errors.Wrap(err)
	}
	// Resolver に任せない。空リストを黙って通すかどうかが実装ごとに変わってしまう
	if len(packages) == 0 {
		return errors.New("package list is empty")
	}

	pacmanConf := filepath.Join(generated, "pacman.conf")
	dbPath := filepath.Join(workDir, "db")
	if err := os.MkdirAll(dbPath, 0o755); err != nil {
		return errors.Newf("failed to create database directory: %w", err)
	}
	if err := s.resolver.Sync(pacmanConf, dbPath); err != nil {
		return errors.Newf("repository sync (mirror or network, not the package list): %w", err)
	}
	return errors.Wrap(s.resolver.Resolve(pacmanConf, dbPath, packages))
}

func readPackageList(filename string) ([]string, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, errors.Newf("failed to read the generated package list: %w", err)
	}
	return lo.FilterMap(strings.Split(string(content), "\n"), func(line string, _ int) (string, bool) {
		name := strings.TrimSpace(line)
		return name, name != "" && !strings.HasPrefix(name, "#")
	}), nil
}

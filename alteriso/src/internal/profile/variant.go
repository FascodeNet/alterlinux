// LLM Generated: Created by Claude
package profile

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

const variantsDirName = "variants"

// variantOwner is a directory that can provide variants: a loaded module or
// the profile itself.
type variantOwner struct {
	name string
	dir  string
	arch ModuleArchitectures
}

// ParseVariants splits the comma separated selection accepted on the command
// line. The order is kept because it decides which variant wins a conflict.
func ParseVariants(selection string) ([]string, error) {
	names := lo.Compact(lo.Map(strings.Split(selection, ","), func(name string, _ int) string {
		return strings.TrimSpace(name)
	}))
	if len(names) == 0 {
		return nil, nil
	}
	if duplicates := lo.FindDuplicates(names); len(duplicates) > 0 {
		return nil, errors.Newf("variant %q is selected more than once", duplicates[0])
	}
	// "." と ".." は filepath.Base が値をそのまま返すので、個別に弾く
	if name, found := lo.Find(names, func(name string) bool {
		return name == "." || name == ".." || filepath.Base(name) != name
	}); found {
		return nil, errors.Newf("variant name %q must be a directory name, not a path", name)
	}
	return names, nil
}

// loadVariant reads one variant directory of an owner and returns nil when the
// owner does not provide it. The manifest is optional because most variants
// only carry files.
func loadVariant(owner variantOwner, variant string) (*Module, error) {
	dir := filepath.Join(owner.dir, variantsDirName, variant)
	if info, err := os.Stat(dir); err != nil || !info.IsDir() {
		return nil, nil
	}

	definition := ModuleDefinition{ManifestVersion: 1, Arch: owner.arch}
	configPath := filepath.Join(dir, moduleManifestName)
	if _, err := os.Stat(configPath); err == nil {
		if err := decodeJSONFile(configPath, "variant config", &definition); err != nil {
			return nil, errors.Wrap(err)
		}
		if !definition.Arch.set {
			definition.Arch = owner.arch
		}
	} else {
		warnUnreachableScripts(dir)
	}

	name := owner.name + ":" + variant
	if err := definition.Validate(name); err != nil {
		return nil, errors.Wrap(err)
	}
	return &Module{Name: name, Definition: definition, Dir: dir}, nil
}

// warnUnreachableScripts reports shell scripts that nothing will ever source,
// because only "load_scripts" in a manifest gets embedded.
func warnUnreachableScripts(dir string) {
	scripts, err := filepath.Glob(filepath.Join(dir, "*.sh"))
	if err != nil || len(scripts) == 0 {
		return
	}
	slog.Warn("Variant scripts are ignored without a manifest", "dir", dir, "manifest", moduleManifestName)
}

// variantOwners lists the directories that can provide variants, in merge
// order. The profile comes last because it is the most specific owner.
func (p *Profile) variantOwners() []variantOwner {
	return append(
		lo.Map(p.modules, func(module Module, _ int) variantOwner {
			return variantOwner{name: module.Name, dir: module.Dir, arch: module.Definition.Arch}
		}),
		variantOwner{name: filepath.Base(p.Dir), dir: p.Dir, arch: ModuleArchitectures{all: true}},
	)
}

// AvailableVariants returns every variant the profile and its modules provide,
// mapped to the owners that provide it in merge order.
func (p *Profile) AvailableVariants() (map[string][]string, error) {
	available := make(map[string][]string)
	for _, owner := range p.variantOwners() {
		entries, err := os.ReadDir(filepath.Join(owner.dir, variantsDirName))
		if err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return nil, errors.Newf("failed to read variants of %s: %w", owner.name, err)
		}
		for _, entry := range entries {
			if entry.IsDir() {
				available[entry.Name()] = append(available[entry.Name()], owner.name)
			}
		}
	}
	return available, nil
}

// loadVariantModules expands the selection into units, grouped by variant so a
// later variant overrides an earlier one, and ordered by owner within a group
// so the profile stays the most specific owner.
func loadVariantModules(loaded *Profile, variants []string) ([]Module, error) {
	owners := loaded.variantOwners()

	var units []Module
	for _, variant := range variants {
		found := 0
		for _, owner := range owners {
			unit, err := loadVariant(owner, variant)
			if err != nil {
				return nil, errors.Wrap(err)
			}
			if unit == nil {
				continue
			}
			slog.Info("Loading variant", "variant", variant, "source", unit.Name, "dir", unit.Dir)
			units = append(units, *unit)
			found++
		}
		if found == 0 {
			return nil, errors.Newf("variant %q is not provided by the profile or any of its modules", variant)
		}
	}
	return units, nil
}

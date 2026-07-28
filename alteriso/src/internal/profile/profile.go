package profile

import (
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

type Profile struct {
	Definition    Definition
	Dir           string
	modules       []Module
	variants      []string
	variantUnits  []Module
	moduleOptions map[string]map[string]any
}

// Source is one directory that contributes files to the generated profile.
type Source struct {
	Name string
	Dir  string
}

// Modules returns a copy of the module list so callers cannot reorder the
// loaded aggregate. Variant units come last, so their hooks and packages apply
// after every base module. Module definitions are treated as read-only.
func (p *Profile) Modules() []Module {
	return append(append([]Module(nil), p.modules...), p.variantUnits...)
}

// Variants returns the selected variant names in the order they were given.
func (p *Profile) Variants() []string {
	return append([]string(nil), p.variants...)
}

// Sources returns every file source in merge order: the base modules, then the
// profile, then the variant units. A later source overwrites an earlier one, so
// a selected variant overrides the profile it is applied to.
func (p *Profile) Sources() []Source {
	sources := lo.Map(p.modules, func(module Module, _ int) Source {
		return Source{Name: module.Name, Dir: module.Dir}
	})
	sources = append(sources, Source{Name: filepath.Base(p.Dir), Dir: p.Dir})
	return append(sources, lo.Map(p.variantUnits, func(unit Module, _ int) Source {
		return Source{Name: unit.Name, Dir: unit.Dir}
	})...)
}

// ModuleOptions returns the option values every loaded module sees, with the
// manifest defaults already applied.
func (p *Profile) ModuleOptions() map[string]map[string]any {
	if p.moduleOptions == nil {
		return nil
	}
	options := make(map[string]map[string]any, len(p.moduleOptions))
	for module, values := range p.moduleOptions {
		options[module] = make(map[string]any, len(values))
		for name, value := range values {
			options[module][name] = value
		}
	}
	return options
}

// ForArchitecture returns an independent profile value resolved for one
// concrete archiso target. The loaded profile remains reusable for another
// architecture.
func (p *Profile) ForArchitecture(architecture string) (*Profile, error) {
	if architecture == "" {
		architecture = p.Definition.Arch
	}
	if err := validateConcreteArchitecture(architecture, "target"); err != nil {
		return nil, errors.Wrap(err)
	}
	for _, module := range p.Modules() {
		if err := module.ValidateArchitecture(architecture); err != nil {
			return nil, errors.Wrap(err)
		}
	}

	resolved := *p
	resolved.Definition = p.Definition
	resolved.Definition.Arch = architecture
	resolved.modules = append([]Module(nil), p.modules...)
	resolved.variantUnits = append([]Module(nil), p.variantUnits...)
	resolved.variants = p.Variants()
	resolved.moduleOptions = p.ModuleOptions()
	return &resolved, nil
}

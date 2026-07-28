package profile

import "github.com/FascodeNet/alterlinux/src/internal/errors"

type Profile struct {
	Definition    Definition
	Dir           string
	modules       []Module
	moduleOptions map[string]map[string]any
}

// Modules returns a copy of the module list so callers cannot reorder the
// loaded aggregate. Module definitions are treated as read-only.
func (p *Profile) Modules() []Module {
	return append([]Module(nil), p.modules...)
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
	for _, module := range p.modules {
		if err := module.ValidateArchitecture(architecture); err != nil {
			return nil, errors.Wrap(err)
		}
	}

	resolved := *p
	resolved.Definition = p.Definition
	resolved.Definition.Arch = architecture
	resolved.modules = append([]Module(nil), p.modules...)
	resolved.moduleOptions = p.ModuleOptions()
	return &resolved, nil
}

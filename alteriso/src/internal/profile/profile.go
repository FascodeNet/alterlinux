package profile

import "github.com/FascodeNet/alterlinux/src/internal/errors"

type Profile struct {
	Definition Definition
	Dir        string
	modules    []Module
}

// Modules returns a copy of the module list so callers cannot reorder the
// loaded aggregate. Module definitions are treated as read-only.
func (p *Profile) Modules() []Module {
	return append([]Module(nil), p.modules...)
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
	return &resolved, nil
}

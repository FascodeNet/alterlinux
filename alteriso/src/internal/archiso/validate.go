package archiso

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

func (p *Profile) Validate() error {
	return p.validateModules()
}

func (p *Profile) validateModules() error {
	valid := p.Modules()
	names := lo.Map(valid, func(item Module, index int) string {
		return item.Name
	})
	for _, mod := range p.Archiso.modules {
		if !lo.Contains(names, mod) {
			return errors.Newf("invalid module: %s", mod)
		}
	}
	return nil
}

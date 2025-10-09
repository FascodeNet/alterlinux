package archiso

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

func (p *Profile) Validate() error {
	return p.validateModules()
}

func (p *Profile) validateModules() error {
	valid := moduleNames()
	for _, mod := range p.Archiso.modules {
		if !lo.Contains(valid, mod) {
			return errors.Newf("invalid module: %s", mod)
		}
	}
	return nil
}

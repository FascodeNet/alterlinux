package profile

import (
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

// Definition is the JSON representation stored in profiledef.json.
type Definition struct {
	Arch              string              `json:"arch"`
	Modules           []string            `json:"modules"`
	OSName            string              `json:"os_name"`
	KernelName        string              `json:"kernel_name"`
	UserName          string              `json:"username"`
	Injects           map[string][]string `json:"injects"`
	COWSpaceSize      string              `json:"cow_spacesize"`
	RequireInjectable bool                `json:"require_injectable"`
	PacmanConf        string              `json:"pacman_conf"`
}

// Validate checks invariants required before modules can be resolved.
func (d Definition) Validate() error {
	if err := validateConcreteArchitecture(d.Arch, "profile"); err != nil {
		return errors.Wrap(err)
	}
	if d.Modules == nil {
		return errors.New(`profile must declare "modules" as an array`)
	}
	seen := make(map[string]struct{}, len(d.Modules))
	for index, name := range d.Modules {
		if name == "" {
			return errors.Newf(`profile contains an empty module name at "modules" index %d`, index)
		}
		if strings.TrimSpace(name) != name {
			return errors.Newf("profile module name %q contains leading or trailing whitespace", name)
		}
		if name == "." || name == ".." || filepath.Base(name) != name {
			return errors.Newf("profile module name %q must be a directory name, not a path", name)
		}
		if _, ok := seen[name]; ok {
			return errors.Newf("profile declares module %q more than once", name)
		}
		seen[name] = struct{}{}
	}
	return nil
}

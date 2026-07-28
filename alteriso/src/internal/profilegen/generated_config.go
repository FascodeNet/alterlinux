// LLM Generated: Created by Claude
package profilegen

import (
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/samber/lo"
)

// generatedConfig is the profiledef.json written into the archiso profile.
// It is the contract loader.sh reads with jq, so it is built explicitly
// instead of re-marshalling the input definition.
type generatedConfig struct {
	Arch          string                    `json:"arch"`
	OSName        string                    `json:"os_name,omitempty"`
	KernelName    string                    `json:"kernel_name,omitempty"`
	UserName      string                    `json:"username,omitempty"`
	COWSpaceSize  string                    `json:"cow_spacesize,omitempty"`
	Modules       []string                  `json:"modules"`
	ModuleOptions map[string]map[string]any `json:"module_options,omitempty"`
}

func buildGeneratedConfig(loaded *profile.Profile) generatedConfig {
	return generatedConfig{
		Arch:         loaded.Definition.Arch,
		OSName:       loaded.Definition.OSName,
		KernelName:   loaded.Definition.KernelName,
		UserName:     loaded.Definition.UserName,
		COWSpaceSize: loaded.Definition.COWSpaceSize,
		Modules: lo.Map(loaded.Modules(), func(module profile.Module, _ int) string {
			return module.Name
		}),
		ModuleOptions: loaded.ModuleOptions(),
	}
}

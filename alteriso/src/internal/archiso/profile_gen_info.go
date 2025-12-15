package archiso

import (
	"encoding/json"
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

type profileInfo struct {
	OSName  string `json:"os_name,omitempty"`
	Arch    string `json:"arch,omitempty"`
	Modules []struct {
		Name            string `json:"name,omitempty"`
		ManifectVersion int    `json:"version,omitempty"`
		ModuleVersion   int    `json:"module_version,omitempty"`
	} `json:"modules,omitempty"`
}

func (p *Profile) ProfileInfo() (*profileInfo, error) {
	info := &profileInfo{
		OSName: p.Config.OSName,
		Arch:   p.Config.Arch,
	}

	for _, mod := range p.Modules() {
		info.Modules = append(info.Modules, struct {
			Name            string `json:"name,omitempty"`
			ManifectVersion int    `json:"version,omitempty"`
			ModuleVersion   int    `json:"module_version,omitempty"`
		}{
			Name:            mod.Name,
			ManifectVersion: mod.Config.ManifestVersion,
			ModuleVersion:   mod.Config.ModuleVersion,
		})
	}

	return info, nil
}

func (p *Profile) generateInfoFile(outDir string) error {
	info, err := p.ProfileInfo()
	if err != nil {
		return err
	}

	bytes, err := json.MarshalIndent(info, "", "  ")
	if err != nil {
		return errors.Wrap(err)
	}

	dst := path.Join(outDir, "alteriso.json")
	if err := os.WriteFile(dst, bytes, 0o644); err != nil {
		return errors.Wrap(err)
	}
	return nil
}

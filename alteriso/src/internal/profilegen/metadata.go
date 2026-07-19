package profilegen

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

type profileInfo struct {
	OSName  string       `json:"os_name,omitempty"`
	Arch    string       `json:"arch,omitempty"`
	Modules []moduleInfo `json:"modules,omitempty"`
}

type moduleInfo struct {
	Name            string `json:"name,omitempty"`
	ManifestVersion int    `json:"version,omitempty"`
	ModuleVersion   int    `json:"module_version,omitempty"`
}

func buildProfileInfo(loaded *profile.Profile) profileInfo {
	info := profileInfo{
		OSName: loaded.Definition.OSName,
		Arch:   loaded.Definition.Arch,
	}
	for _, module := range loaded.Modules() {
		info.Modules = append(info.Modules, moduleInfo{
			Name:            module.Name,
			ManifestVersion: module.Definition.ManifestVersion,
			ModuleVersion:   module.Definition.ModuleVersion,
		})
	}
	return info
}

func generateInfoFile(loaded *profile.Profile, outDir string) error {
	content, err := json.MarshalIndent(buildProfileInfo(loaded), "", "  ")
	if err != nil {
		return errors.Newf("failed to encode profile metadata: %w", err)
	}
	destination := filepath.Join(outDir, "alteriso.json")
	if err := os.WriteFile(destination, content, 0o644); err != nil {
		return errors.Newf("failed to write profile metadata: %w", err)
	}
	return nil
}

package profile

import (
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

const profileManifestName = "profiledef.json"

// Load assembles a validated Profile from its definition and selected modules.
// Generation-specific settings intentionally do not belong here.
func Load(dir, modulesDir string) (*Profile, error) {
	var definition Definition
	if err := decodeJSONFile(filepath.Join(dir, profileManifestName), "profile config", &definition); err != nil {
		return nil, errors.Wrap(err)
	}
	if err := definition.Validate(); err != nil {
		return nil, errors.Wrap(err)
	}

	loaded := &Profile{
		Definition: definition,
		Dir:        dir,
	}
	for _, name := range definition.Modules {
		module, err := LoadModule(filepath.Join(modulesDir, name))
		if err != nil {
			return nil, errors.Newf("failed to load module %s: %w", name, err)
		}
		loaded.modules = append(loaded.modules, *module)
	}

	return loaded, nil
}

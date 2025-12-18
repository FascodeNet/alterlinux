package archiso

import (
	"encoding/json"
	"fmt"
	"os"
	"path"
)

type profileOption func(*Profile) error

// func WithPacmanCacheDir(dir string) profileOption {
// 	return func(p *Profile) error {
// 		p.PacmanCacheDir = dir
// 		return nil
// 	}
// }

func WithModulesPath(dir string) profileOption {
	return func(p *Profile) error {
		p.ModulesPath = dir
		return nil
	}
}

func WithbootloadersPath(dir string) profileOption {
	return func(p *Profile) error {
		p.BootloadersPath = dir
		return nil
	}
}

func NewProfile(dir string, opts ...profileOption) (*Profile, error) {
	configFile, err := os.ReadFile(path.Join(dir, "profiledef.json"))
	if err != nil {
		return nil, fmt.Errorf("failed to read profile config: %w", err)
	}

	profile := Profile{
		Path: dir,
	}
	if err := json.Unmarshal(configFile, &profile.Config); err != nil {
		return nil, fmt.Errorf("failed to parse profile config: %w", err)
	}

	for _, opt := range opts {
		if err := opt(&profile); err != nil {
			return nil, err
		}
	}

	// Load modules
	for _, modName := range profile.Config.Modules {
		modDir := path.Join(profile.ModulesPath, modName)
		mod, err := NewModule(modDir)
		if err != nil {
			return nil, fmt.Errorf("failed to load module %s: %w", modName, err)
		}
		profile.modules = append(profile.modules, *mod)
	}

	return &profile, nil
}

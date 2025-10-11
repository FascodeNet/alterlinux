package archiso

import (
	"encoding/json"
	"fmt"
	"os"
	"path"
)

type Profile struct {
	Config          ProfileDef
	modules         []Module
	Path            string
	BootloadersPath string
}

type ProfileDef struct {
	Arch       string   `json:"arch"`
	Modules    []string `json:"modules"`
	KernelName string   `json:"kernel_name"`
	UserName   string   `json:"username"`
}

func NewProfile(dir, bootloadersPath, modulesPath string) (*Profile, error) {
	configFile, err := os.ReadFile(path.Join(dir, "profiledef.json"))
	if err != nil {
		return nil, fmt.Errorf("failed to read profile config: %w", err)
	}

	profile := Profile{}

	if err := json.Unmarshal(configFile, &profile.Config); err != nil {
		return nil, fmt.Errorf("failed to parse profile config: %w", err)
	}

	profile.Path = dir
	profile.BootloadersPath = bootloadersPath

	for _, modName := range profile.Config.Modules {
		modDir := path.Join(modulesPath, modName)
		mod, err := NewModule(modDir)
		if err != nil {
			return nil, fmt.Errorf("failed to load module %s: %w", modName, err)
		}
		profile.modules = append(profile.modules, *mod)
	}

	return &profile, nil
}

package archiso

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
)

type Module struct {
	Name   string
	Config *ModuleConfig
	Path   string
}

type ModuleConfig struct {
	ManifestVersion int                 `json:"manifest_version"`
	ModuleVersion   int                 `json:"module_version"`
	LoadScripts     []string            `json:"load_scripts"`
	Injects         map[string][]string `json:"injects"`
}

func NewModule(dir string) (*Module, error) {
	if !futils.Exists(dir) {
		return nil, errors.Newf("module directory does not exist: %s", dir)
	}
	configPath := path.Join(dir, "alteriso.json")
	if !futils.Exists(configPath) {
		return nil, fmt.Errorf("module does not contain alteriso.json: %s", dir)
	}
	configFile, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read module config: %w", err)
	}
	var config ModuleConfig
	if err := json.Unmarshal(configFile, &config); err != nil {
		return nil, fmt.Errorf("failed to parse module config: %w", err)
	}
	if config.ManifestVersion != 1 {
		return nil, fmt.Errorf("unsupported manifest version: %d", config.ManifestVersion)
	}
	return &Module{
		Name:   path.Base(dir),
		Config: &config,
		Path:   dir,
	}, nil
}

func AvailableModules(modulesDir string) []Module {
	slog.Info("Listing available modules", "path", modulesDir)

	modules := []Module{}
	l, err := os.ReadDir(modulesDir)
	if err != nil {
		slog.Error("Failed to read modules directory", "error", err)
		return nil
	}
	for _, entry := range l {
		if !entry.IsDir() {
			continue
		}
		modDir := path.Join(modulesDir, entry.Name())
		mod, err := NewModule(modDir)
		if err != nil {
			slog.Warn("Failed to load module", "module", entry.Name(), "error", err)
			continue
		}
		modules = append(modules, *mod)
	}

	return modules
}

func (p *Profile) Modules() []Module {
	return p.modules
}

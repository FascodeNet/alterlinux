package profile

import (
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

const moduleManifestName = "alteriso.json"

// filePermissionPattern matches the uid:gid:mode form mkarchiso expects.
var filePermissionPattern = regexp.MustCompile(`^[0-9]+:[0-9]+:[0-7]{3,4}$`)

type Module struct {
	Name       string
	Definition ModuleDefinition
	Dir        string
}

type ModuleDefinition struct {
	ManifestVersion   int                 `json:"manifest_version"`
	ModuleVersion     int                 `json:"module_version"`
	Arch              ModuleArchitectures `json:"arch"`
	LoadScripts       []string            `json:"load_scripts"`
	Injects           map[string][]string `json:"injects"`
	AppendKernelParam []string            `json:"append_kernel_param"`
	FilePermissions   map[string]string   `json:"file_permissions"`
}

func (d ModuleDefinition) Validate() error {
	if d.ManifestVersion != 1 {
		return errors.Newf("unsupported manifest version: %d", d.ManifestVersion)
	}
	if err := d.Arch.validate(); err != nil {
		return errors.Wrap(err)
	}
	return errors.Wrap(d.validateFilePermissions())
}

func (d ModuleDefinition) validateFilePermissions() error {
	paths := make([]string, 0, len(d.FilePermissions))
	for path := range d.FilePermissions {
		paths = append(paths, path)
	}
	slices.Sort(paths)

	for _, path := range paths {
		if path == "" {
			return errors.New(`module declares an empty path in "file_permissions"`)
		}
		if !strings.HasPrefix(path, "/") {
			return errors.Newf("module file permission path %q must be absolute", path)
		}
		// The path is emitted into profiledef.sh as a quoted array key.
		if strings.ContainsAny(path, "\"$\\`") {
			return errors.Newf("module file permission path %q contains an unsupported character", path)
		}
		if permission := d.FilePermissions[path]; !filePermissionPattern.MatchString(permission) {
			return errors.Newf("module file permission %q for %q must be in uid:gid:mode form", permission, path)
		}
	}
	return nil
}

func LoadModule(dir string) (*Module, error) {
	info, err := os.Stat(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, errors.Newf("module directory does not exist: %s", dir)
		}
		return nil, errors.Newf("failed to access module directory %s: %w", dir, err)
	}
	if !info.IsDir() {
		return nil, errors.Newf("module path is not a directory: %s", dir)
	}

	configPath := filepath.Join(dir, moduleManifestName)
	var definition ModuleDefinition
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return nil, errors.Newf("module does not contain %s: %s", moduleManifestName, dir)
	}
	if err := decodeJSONFile(configPath, "module config", &definition); err != nil {
		return nil, errors.Wrap(err)
	}
	if err := definition.Validate(); err != nil {
		return nil, errors.Wrap(err)
	}

	return &Module{
		Name:       filepath.Base(dir),
		Definition: definition,
		Dir:        dir,
	}, nil
}

func (m Module) SupportsArchitecture(architecture string) bool {
	return m.Definition.Arch.Supports(architecture)
}

func (m Module) ValidateArchitecture(architecture string) error {
	if err := validateConcreteArchitecture(architecture, "target"); err != nil {
		return errors.Wrap(err)
	}
	if !m.SupportsArchitecture(architecture) {
		return errors.Newf(
			"module %q does not support target architecture %q (supported architectures: %s)",
			m.Name,
			architecture,
			m.Definition.Arch,
		)
	}
	return nil
}

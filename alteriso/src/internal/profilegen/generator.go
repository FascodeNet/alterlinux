package profilegen

import (
	"log/slog"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/buildinfo"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	cp "github.com/otiai10/copy"
)

type Options struct {
	// BootloadersDir supplies the shared bootloader templates.
	BootloadersDir string
	// Arch selects one target for this generation. Empty uses Definition.Arch.
	Arch string
	// NoConfirm suppresses the generated profile's confirmation prompt.
	NoConfirm bool
}

func prepareProfile(loaded *profile.Profile, options Options) (*profile.Profile, error) {
	if loaded == nil {
		return nil, errors.New("profile must not be nil")
	}
	resolved, err := loaded.ForArchitecture(options.Arch)
	if err != nil {
		return nil, errors.Wrap(err)
	}
	if err := requirePath(resolved.Dir, "profile directory", directory); err != nil {
		return nil, errors.Wrap(err)
	}
	if err := requirePath(options.BootloadersDir, "bootloaders directory", directory); err != nil {
		return nil, errors.Wrap(err)
	}
	if err := requirePath(profileDefPath(resolved), "profiledef.sh", regularFile); err != nil {
		return nil, errors.Wrap(err)
	}
	if err := requirePath(pacmanConfPath(resolved), "pacman.conf", regularFile); err != nil {
		return nil, errors.Wrap(err)
	}
	return resolved, nil
}

// Generate renders a loaded alteriso profile into an archiso profile.
func Generate(loaded *profile.Profile, outDir string, options Options) error {
	if outDir == "" {
		return errors.New("output directory must not be empty")
	}
	resolved, err := prepareProfile(loaded, options)
	if err != nil {
		return errors.Wrap(err)
	}
	generatorInfo := buildinfo.Current()

	tempDir, err := os.MkdirTemp("", "alteriso-*")
	if err != nil {
		return errors.Newf("failed to create profile staging directory: %w", err)
	}
	defer func() {
		_ = os.RemoveAll(tempDir)
	}()

	tasks := []struct {
		name string
		run  func(string) error
	}{
		{"bootloader configs", func(dir string) error {
			return errors.Wrap(generateBootloaderConfigs(resolved, dir, options))
		}},
		{"splash image", func(dir string) error {
			return errors.Wrap(copySplashImage(resolved, dir))
		}},
		{"profile definition", func(dir string) error {
			return errors.Wrap(generateProfileDefinition(resolved, dir, options))
		}},
		{"injecter", copyInjecter},
		{"airootfs", func(dir string) error {
			return errors.Wrap(copyAirootfs(resolved, dir))
		}},
		{"package lists", func(dir string) error {
			return errors.Wrap(generatePackageFiles(resolved, dir))
		}},
		{"pacman config", func(dir string) error {
			return errors.Wrap(copyPacmanConf(resolved, dir))
		}},
		{"profile metadata", func(dir string) error {
			return errors.Wrap(generateInfoFile(resolved, dir, generatorInfo))
		}},
	}

	for _, task := range tasks {
		if err := task.run(tempDir); err != nil {
			slog.Error("Failed to generate archiso profile", "task", task.name, "error", errors.Wrap(err))
			return errors.Newf("%s: %w", task.name, err)
		}
	}

	if err := cp.Copy(tempDir, outDir); err != nil {
		return errors.Newf("failed to copy generated profile to %s: %w", outDir, err)
	}
	return nil
}

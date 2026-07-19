package application

import (
	"log/slog"
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

// ProfileInput identifies a reusable alteriso profile and the one archiso
// target to generate from it.
type ProfileInput struct {
	Dir        string
	ModulesDir string
	Generation profilegen.Options
}

type isoBuilder interface {
	Build(archiso.BuildRequest) error
}

// ProfileService owns the use-case boundary. Cobra commands only translate
// flags and arguments into method parameters.
type ProfileService struct {
	loadProfile     func(string, string) (*profile.Profile, error)
	generateProfile func(*profile.Profile, string, profilegen.Options) error
	builder         isoBuilder
}

func NewProfileService() *ProfileService {
	return &ProfileService{
		loadProfile:     profile.Load,
		generateProfile: profilegen.Generate,
		builder:         archiso.NewBuilder(),
	}
}

func (s *ProfileService) Generate(input ProfileInput, outputDir string) error {
	if input.Dir == "" {
		return errors.New("profile source directory must not be empty")
	}
	if outputDir == "" {
		return errors.New("profile output directory must not be empty")
	}
	if _, err := os.Stat(outputDir); err == nil {
		return errors.Newf("output directory already exists: %s", outputDir)
	} else if !os.IsNotExist(err) {
		return errors.Newf("failed to inspect output directory %s: %w", outputDir, err)
	}

	loaded, err := s.load(input)
	if err != nil {
		return errors.Wrap(err)
	}
	if err := s.generateProfile(loaded, outputDir, input.Generation); err != nil {
		return errors.Newf("failed to generate archiso profile: %w", err)
	}
	slog.Info("Generated archiso profile", "dir", outputDir)
	return nil
}

func (s *ProfileService) Build(input ProfileInput, outputDir, workDir string) error {
	if input.Dir == "" {
		return errors.New("profile source directory must not be empty")
	}
	if outputDir == "" {
		return errors.New("ISO output directory must not be empty")
	}
	if workDir == "" {
		return errors.New("working directory must not be empty")
	}

	loaded, err := s.load(input)
	if err != nil {
		return errors.Wrap(err)
	}
	outputDir, err = absoluteDirectory(outputDir)
	if err != nil {
		return errors.Wrap(err)
	}
	workDir, err = absoluteDirectory(workDir)
	if err != nil {
		return errors.Wrap(err)
	}

	generatedProfileDir := filepath.Join(workDir, "profile")
	if err := s.generateProfile(loaded, generatedProfileDir, input.Generation); err != nil {
		return errors.Newf("failed to generate archiso profile: %w", err)
	}
	slog.Info("Generated archiso profile", "dir", generatedProfileDir)

	archisoWorkDir := filepath.Join(workDir, "archiso")
	pacmanCacheDir := filepath.Join(workDir, "pacman_cache")
	for _, dir := range []string{archisoWorkDir, pacmanCacheDir} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return errors.Newf("failed to create directory %s: %w", dir, err)
		}
	}
	return errors.Wrap(s.builder.Build(archiso.BuildRequest{
		ProfileDir:     generatedProfileDir,
		WorkDir:        archisoWorkDir,
		OutputDir:      outputDir,
		PacmanCacheDir: pacmanCacheDir,
	}))
}

func (s *ProfileService) load(input ProfileInput) (*profile.Profile, error) {
	slog.Info("Loading profile", "config", input.Dir)
	loaded, err := s.loadProfile(input.Dir, input.ModulesDir)
	if err != nil {
		return nil, errors.Newf("failed to load profile: %w", err)
	}
	slog.Info("Using profile", "name", filepath.Base(input.Dir))
	return loaded, nil
}

func absoluteDirectory(dir string) (string, error) {
	absolute, err := filepath.Abs(dir)
	if err != nil {
		return "", errors.Newf("failed to resolve directory %s: %w", dir, err)
	}
	if err := os.MkdirAll(absolute, 0o755); err != nil {
		return "", errors.Newf("failed to create directory %s: %w", absolute, err)
	}
	return absolute, nil
}

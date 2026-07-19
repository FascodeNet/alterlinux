package application

import (
	"path/filepath"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

type recordingBuilder struct {
	request archiso.BuildRequest
	err     error
}

func (b *recordingBuilder) Build(request archiso.BuildRequest) error {
	b.request = request
	return b.err
}

func TestProfileServiceGenerateCoordinatesBoundaries(t *testing.T) {
	loaded := &profile.Profile{Definition: profile.Definition{Arch: "i686"}, Dir: "/source"}
	var loadDir, modulesDir string
	var generatedProfile *profile.Profile
	var generatedDir string
	var generationOptions profilegen.Options
	service := &ProfileService{
		loadProfile: func(dir, modules string) (*profile.Profile, error) {
			loadDir = dir
			modulesDir = modules
			return loaded, nil
		},
		generateProfile: func(input *profile.Profile, outDir string, options profilegen.Options) error {
			generatedProfile = input
			generatedDir = outDir
			generationOptions = options
			return nil
		},
		builder: &recordingBuilder{},
	}
	outputDir := filepath.Join(t.TempDir(), "generated")
	input := ProfileInput{
		Dir:        "/source",
		ModulesDir: "/modules",
		Generation: profilegen.Options{
			BootloadersDir: "/bootloaders",
			Arch:           "i686",
			NoConfirm:      true,
		},
	}

	if err := service.Generate(input, outputDir); err != nil {
		t.Fatalf("ProfileService.Generate() error = %v", err)
	}
	if loadDir != "/source" {
		t.Errorf("loader directory = %q, want /source", loadDir)
	}
	if modulesDir != "/modules" {
		t.Errorf("loader modules directory = %q", modulesDir)
	}
	if generatedProfile != loaded || generatedDir != outputDir {
		t.Errorf("generator input = (%p, %q), want (%p, %q)", generatedProfile, generatedDir, loaded, outputDir)
	}
	if generationOptions.BootloadersDir != "/bootloaders" ||
		generationOptions.Arch != "i686" ||
		!generationOptions.NoConfirm {
		t.Errorf("generator options = %#v", generationOptions)
	}
}

func TestProfileServiceBuildCoordinatesGenerationAndMkarchiso(t *testing.T) {
	root := t.TempDir()
	loaded := &profile.Profile{Definition: profile.Definition{Arch: "x86_64"}, Dir: "/source"}
	var generatedDir string
	builder := &recordingBuilder{}
	service := &ProfileService{
		loadProfile: func(dir, modules string) (*profile.Profile, error) {
			return loaded, nil
		},
		generateProfile: func(input *profile.Profile, outDir string, options profilegen.Options) error {
			generatedDir = outDir
			return nil
		},
		builder: builder,
	}
	workDir := filepath.Join(root, "work")
	outputDir := filepath.Join(root, "out")

	if err := service.Build(
		ProfileInput{
			Dir:        "/source",
			ModulesDir: "/modules",
			Generation: profilegen.Options{
				BootloadersDir: "/bootloaders",
			},
		},
		outputDir,
		workDir,
	); err != nil {
		t.Fatalf("ProfileService.Build() error = %v", err)
	}

	if got, want := generatedDir, filepath.Join(workDir, "profile"); got != want {
		t.Errorf("generated profile directory = %q, want %q", got, want)
	}
	if got, want := builder.request.ProfileDir, filepath.Join(workDir, "profile"); got != want {
		t.Errorf("builder profile directory = %q, want %q", got, want)
	}
	if got, want := builder.request.WorkDir, filepath.Join(workDir, "archiso"); got != want {
		t.Errorf("builder work directory = %q, want %q", got, want)
	}
	if got, want := builder.request.PacmanCacheDir, filepath.Join(workDir, "pacman_cache"); got != want {
		t.Errorf("builder cache directory = %q, want %q", got, want)
	}
	if builder.request.OutputDir != outputDir {
		t.Errorf("builder output directory = %q, want %q", builder.request.OutputDir, outputDir)
	}
}

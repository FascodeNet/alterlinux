package archiso

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
)

//go:embed testprofile
var testProfile embed.FS

func extractTestProfile(destination string) error {
	err := fs.WalkDir(testProfile, "testprofile", func(source string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return errors.Wrap(walkErr)
		}
		relative, err := filepath.Rel("testprofile", source)
		if err != nil {
			return errors.Wrap(err)
		}
		target := filepath.Join(destination, relative)
		if entry.IsDir() {
			return errors.Wrap(os.MkdirAll(target, 0o755))
		}
		content, err := testProfile.ReadFile(source)
		if err != nil {
			return errors.Wrap(err)
		}
		if err := os.WriteFile(target, content, 0o644); err != nil {
			return errors.Wrap(err)
		}
		return nil
	})
	return errors.Wrap(err)
}

// CheckInjectability verifies patched mkarchiso behavior with a generated
// minimal profile.
func CheckInjectability() (bool, error) {
	injectable, err := checkInjectability(executeCommand)
	return injectable, errors.Wrap(err)
}

func checkInjectability(execute commandExecutor) (bool, error) {
	tempDir, err := os.MkdirTemp("", "alteriso-injectable-test-")
	if err != nil {
		return false, errors.Newf("failed to create injectability test directory: %w", err)
	}
	defer func() {
		_ = os.RemoveAll(tempDir)
	}()

	sourceDir := filepath.Join(tempDir, "alteriso")
	generatedDir := filepath.Join(tempDir, "archiso")
	if err := extractTestProfile(sourceDir); err != nil {
		return false, errors.Newf("failed to extract injectability test profile: %w", err)
	}

	loaded, err := profile.Load(sourceDir, "")
	if err != nil {
		return false, errors.Newf("failed to load injectability test profile: %w", err)
	}
	err = profilegen.Generate(loaded, generatedDir, profilegen.Options{
		BootloadersDir: sourceDir,
	})
	if err != nil {
		return false, errors.Newf("failed to generate injectability test profile: %w", err)
	}

	err = execute(command{
		path: "fakeroot",
		args: []string{"mkarchiso", "-v", generatedDir},
		env:  os.Environ(),
	})
	if err != nil {
		return false, nil
	}
	return true, nil
}

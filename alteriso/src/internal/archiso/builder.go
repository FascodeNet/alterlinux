package archiso

import (
	"log/slog"
	"os"
	"os/exec"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/exutils"
)

type BuildRequest struct {
	ProfileDir     string
	WorkDir        string
	OutputDir      string
	PacmanCacheDir string
}

type command struct {
	path  string
	args  []string
	env   []string
	stdio bool
}

type commandExecutor func(command) error

func executeCommand(spec command) error {
	cmd := exutils.CommandWithStdio(spec.path, spec.args...)
	if !spec.stdio {
		cmd = exec.Command(spec.path, spec.args...)
	}
	cmd.Env = spec.env
	return errors.Wrap(cmd.Run())
}

// Builder is the process boundary around mkarchiso.
type Builder struct {
	lookPath func(string) (string, error)
	executor commandExecutor
}

func NewBuilder() *Builder {
	return &Builder{
		lookPath: exec.LookPath,
		executor: executeCommand,
	}
}

func (b *Builder) Build(request BuildRequest) error {
	if request.ProfileDir == "" {
		return errors.New("archiso profile directory must not be empty")
	}
	if request.WorkDir == "" {
		return errors.New("archiso work directory must not be empty")
	}
	if request.OutputDir == "" {
		return errors.New("ISO output directory must not be empty")
	}
	if request.PacmanCacheDir == "" {
		return errors.New("pacman cache directory must not be empty")
	}

	mkarchisoPath, err := b.lookPath("mkarchiso")
	if err != nil {
		return errors.Newf("failed to find mkarchiso: %w", err)
	}
	args := []string{
		"-v",
		"-w", request.WorkDir,
		"-o", request.OutputDir,
		request.ProfileDir,
	}
	slog.Info("Building ISO image", "command", mkarchisoPath, "args", args)
	if err := b.executor(command{
		path:  mkarchisoPath,
		args:  args,
		env:   append(os.Environ(), "ALTERISO_PACMAN_CACHE="+request.PacmanCacheDir),
		stdio: true,
	}); err != nil {
		return errors.Newf("mkarchiso failed: %w", err)
	}
	return nil
}

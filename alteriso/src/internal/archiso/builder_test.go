package archiso

import (
	"slices"
	"testing"
)

type recordingExecutor struct {
	command command
	err     error
}

func (e *recordingExecutor) Run(spec command) error {
	e.command = spec
	return e.err
}

func TestBuilderBuildsExpectedCommand(t *testing.T) {
	executor := &recordingExecutor{}
	builder := &Builder{
		lookPath: func(name string) (string, error) {
			if name != "mkarchiso" {
				t.Fatalf("lookPath(%q), want mkarchiso", name)
			}
			return "/usr/bin/mkarchiso", nil
		},
		executor: executor.Run,
	}
	request := BuildRequest{
		ProfileDir:     "/work/profile",
		WorkDir:        "/work/archiso",
		OutputDir:      "/output",
		PacmanCacheDir: "/work/pacman_cache",
	}
	if err := builder.Build(request); err != nil {
		t.Fatalf("Builder.Build() error = %v", err)
	}

	if got, want := executor.command.path, "/usr/bin/mkarchiso"; got != want {
		t.Errorf("command path = %q, want %q", got, want)
	}
	wantArgs := []string{"-v", "-w", "/work/archiso", "-o", "/output", "/work/profile"}
	if !slices.Equal(executor.command.args, wantArgs) {
		t.Errorf("command args = %#v, want %#v", executor.command.args, wantArgs)
	}
	if !executor.command.stdio {
		t.Error("command stdio = false, want true")
	}
	if !slices.Contains(executor.command.env, "ALTERISO_PACMAN_CACHE=/work/pacman_cache") {
		t.Errorf("command environment does not contain ALTERISO_PACMAN_CACHE: %#v", executor.command.env)
	}
}

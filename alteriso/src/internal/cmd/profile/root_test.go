package profile

import (
	"errors"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/application"
	profiledomain "github.com/FascodeNet/alterlinux/src/internal/profile"
)

type recordingService struct {
	generateInput  application.ProfileInput
	generateOutput string
	buildInput     application.ProfileInput
	buildOutput    string
	buildWork      string
}

func (s *recordingService) Generate(input application.ProfileInput, outputDir string) error {
	s.generateInput = input
	s.generateOutput = outputDir
	return nil
}

func (s *recordingService) Build(input application.ProfileInput, outputDir, workDir string) error {
	s.buildInput = input
	s.buildOutput = outputDir
	s.buildWork = workDir
	return nil
}

func TestGenerateCommandTranslatesFlagsToRequest(t *testing.T) {
	service := &recordingService{}
	cmd := newCommand(service)
	cmd.SetArgs([]string{
		"--modules", "/modules",
		"--bootloaders", "/bootloaders",
		"--noconfirm",
		"--arch", "i686",
		"generate", "/profile",
		"--out", "/generated",
	})
	if err := cmd.Execute(); err != nil {
		t.Fatalf("command error = %v", err)
	}

	input := service.generateInput
	if input.Dir != "/profile" || service.generateOutput != "/generated" {
		t.Errorf("generate input = %#v, output = %q", input, service.generateOutput)
	}
	if input.ModulesDir != "/modules" ||
		input.Generation.BootloadersDir != "/bootloaders" ||
		input.Generation.Arch != "i686" ||
		!input.Generation.NoConfirm {
		t.Errorf("generate input = %#v", input)
	}
}

func TestBuildCommandUsesDefaultProfile(t *testing.T) {
	service := &recordingService{}
	cmd := newCommand(service)
	cmd.SetArgs([]string{"build", "--out", "/out", "--work", "/work"})
	if err := cmd.Execute(); err != nil {
		t.Fatalf("command error = %v", err)
	}
	if got, want := service.buildInput.Dir, "./configs/xfce"; got != want {
		t.Errorf("build source = %q, want %q", got, want)
	}
}

func TestFormatCommandReportsNotImplemented(t *testing.T) {
	cmd := newCommand(&recordingService{})
	cmd.SetArgs([]string{"format", "/profile"})
	err := cmd.Execute()
	if !errors.Is(err, profiledomain.ErrFormatNotImplemented) {
		t.Fatalf("format error = %v, want ErrFormatNotImplemented", err)
	}
}

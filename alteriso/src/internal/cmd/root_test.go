package cmd

import (
	"bytes"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/buildinfo"
)

func TestRootCommandReportsBuildVersion(t *testing.T) {
	command := rootCmd()
	var output bytes.Buffer
	command.SetOut(&output)
	command.SetErr(&output)
	command.SetArgs([]string{"--version"})

	if err := command.Execute(); err != nil {
		t.Fatalf("alteriso --version error = %v", err)
	}
	if want := buildinfo.Current().Version; !strings.Contains(output.String(), want) {
		t.Errorf("alteriso --version output = %q, want version %q", output.String(), want)
	}
}

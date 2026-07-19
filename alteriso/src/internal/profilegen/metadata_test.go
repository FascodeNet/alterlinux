package profilegen

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/buildinfo"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func TestBuildProfileInfoIncludesGeneratorBinary(t *testing.T) {
	binary := buildinfo.Info{
		Version:   "6.0.0",
		Revision:  "test-revision",
		GoVersion: "go-test",
	}
	loaded := &profile.Profile{
		Definition: profile.Definition{
			OSName: "Test Linux",
			Arch:   "x86_64",
		},
	}

	got := buildProfileInfo(loaded, binary)
	if got.OSName != "Test Linux" || got.Arch != "x86_64" || got.AlterISO != binary {
		t.Errorf("buildProfileInfo() = %#v", got)
	}
}

func TestProfileInfoOmitsUnavailableRevision(t *testing.T) {
	info := profileInfo{
		AlterISO: buildinfo.Info{
			Version:   "devel",
			GoVersion: "go-test",
		},
	}
	content, err := json.Marshal(info)
	if err != nil {
		t.Fatalf("failed to encode profile metadata: %v", err)
	}
	if strings.Contains(string(content), `"revision"`) {
		t.Errorf("profile metadata contains an unavailable revision: %s", content)
	}
}

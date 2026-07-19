package buildinfo

import (
	"runtime/debug"
	"testing"
)

func TestResolve(t *testing.T) {
	tests := []struct {
		name             string
		versionOverride  string
		revisionOverride string
		buildInfo        *debug.BuildInfo
		wantVersion      string
		wantRevision     string
		wantGoVersion    string
	}{
		{
			name:             "linker values take precedence",
			versionOverride:  "v6.1.0",
			revisionOverride: "release-revision",
			buildInfo: &debug.BuildInfo{
				GoVersion: "go-test",
				Main:      debug.Module{Version: "v6.0.0"},
				Settings:  []debug.BuildSetting{{Key: "vcs.revision", Value: "vcs-revision"}},
			},
			wantVersion:   "6.1.0",
			wantRevision:  "release-revision",
			wantGoVersion: "go-test",
		},
		{
			name: "Go build information is the fallback",
			buildInfo: &debug.BuildInfo{
				GoVersion: "go-test",
				Main:      debug.Module{Version: "v6.0.0"},
				Settings:  []debug.BuildSetting{{Key: "vcs.revision", Value: "vcs-revision"}},
			},
			wantVersion:   "6.0.0",
			wantRevision:  "vcs-revision",
			wantGoVersion: "go-test",
		},
		{
			name: "development build needs no external metadata",
			buildInfo: &debug.BuildInfo{
				GoVersion: "go-test",
				Main:      debug.Module{Version: "(devel)"},
			},
			wantVersion:   "devel",
			wantGoVersion: "go-test",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := resolve(test.versionOverride, test.revisionOverride, test.buildInfo)
			if got.Version != test.wantVersion ||
				got.Revision != test.wantRevision ||
				got.GoVersion != test.wantGoVersion {
				t.Errorf("resolve() = %#v", got)
			}
		})
	}
}

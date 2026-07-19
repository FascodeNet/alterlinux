// Package buildinfo exposes provenance embedded in the alteriso binary.
package buildinfo

import (
	"runtime"
	"runtime/debug"
	"strings"
)

const developmentVersion = "devel"

// These variables are intentionally settable with go build -ldflags -X.
var (
	version  string
	revision string
)

// Info identifies the alteriso binary that generated a profile.
type Info struct {
	Version   string `json:"version"`
	Revision  string `json:"revision,omitempty"`
	GoVersion string `json:"go_version,omitempty"`
}

// Current returns the build information embedded in the running binary.
func Current() Info {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return resolve(version, revision, nil)
	}
	return resolve(version, revision, info)
}

func resolve(versionOverride, revisionOverride string, info *debug.BuildInfo) Info {
	current := Info{
		Version:   normalizeVersion(versionOverride),
		Revision:  strings.TrimSpace(revisionOverride),
		GoVersion: runtime.Version(),
	}
	if info != nil {
		if info.GoVersion != "" {
			current.GoVersion = info.GoVersion
		}
		if current.Version == "" && info.Main.Version != "" && info.Main.Version != "(devel)" {
			current.Version = normalizeVersion(info.Main.Version)
		}
		if current.Revision == "" {
			for _, setting := range info.Settings {
				if setting.Key == "vcs.revision" {
					current.Revision = strings.TrimSpace(setting.Value)
					break
				}
			}
		}
	}
	if current.Version == "" {
		current.Version = developmentVersion
	}
	return current
}

func normalizeVersion(value string) string {
	return strings.TrimPrefix(strings.TrimSpace(value), "v")
}

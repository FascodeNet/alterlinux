package profilegen

import (
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

type pathKind uint8

const (
	regularFile pathKind = iota
	directory
)

func pathExists(name string, kind pathKind) bool {
	info, err := os.Stat(name)
	if err != nil {
		return false
	}
	return info.IsDir() == (kind == directory)
}

// architectureLayers returns merge order from the legacy unsuffixed form to
// the explicit all-architecture and target-specific forms.
func architectureLayers(base, architecture string) []string {
	return []string{
		base,
		base + ".any",
		base + "." + architecture,
	}
}

func requirePath(name, label string, kind pathKind) error {
	info, err := os.Stat(name)
	if err != nil {
		return errors.Newf("%s is not accessible at %s: %w", label, name, err)
	}
	if kind == directory && !info.IsDir() {
		return errors.Newf("%s is not a directory: %s", label, name)
	}
	if kind == regularFile && info.IsDir() {
		return errors.Newf("%s is not a file: %s", label, name)
	}
	return nil
}

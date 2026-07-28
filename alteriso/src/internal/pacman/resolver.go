// LLM Generated: Created by Claude
package pacman

import (
	"os/exec"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

// Resolver answers whether a generated package list can be installed, without
// building an ISO. Syncing and resolving are separate calls so a mirror outage
// is not reported as a broken package list.
type Resolver interface {
	Sync(configPath, dbPath string) error
	Resolve(configPath, dbPath string, packages []string) error
}

// ExecResolver drives the pacman binary. It needs root because pacman refuses
// -S operations for other users, even with a private dbpath.
type ExecResolver struct {
	Binary string
}

func NewExecResolver() ExecResolver {
	return ExecResolver{Binary: "pacman"}
}

func (r ExecResolver) binary() string {
	if r.Binary == "" {
		return "pacman"
	}
	return r.Binary
}

func (r ExecResolver) Sync(configPath, dbPath string) error {
	return errors.Wrap(r.run("-Sy", "--config", configPath, "--dbpath", dbPath, "--noconfirm"))
}

func (r ExecResolver) Resolve(configPath, dbPath string, packages []string) error {
	// pacman syncs and exits 0 when given no targets, so an empty list would
	// otherwise pass as a successful check.
	if len(packages) == 0 {
		return errors.New("package list is empty")
	}
	args := append(
		[]string{"-Sp", "--config", configPath, "--dbpath", dbPath, "--noconfirm"},
		packages...,
	)
	return errors.Wrap(r.run(args...))
}

func (r ExecResolver) run(args ...string) error {
	output, err := exec.Command(r.binary(), args...).CombinedOutput()
	if err == nil {
		return nil
	}
	message := strings.TrimSpace(string(output))
	if message == "" {
		return errors.Newf("%s %s: %w", r.binary(), args[0], err)
	}
	return errors.Newf("%s %s: %w: %s", r.binary(), args[0], err, lastLines(message, 5))
}

func lastLines(text string, count int) string {
	lines := strings.Split(text, "\n")
	if len(lines) <= count {
		return text
	}
	return strings.Join(lines[len(lines)-count:], "\n")
}

package application

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"os/user"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/go-distro"
	"github.com/Hayao0819/go-distro/linux"
	"github.com/Jguer/go-alpm/v2"
	"github.com/go-git/go-git/v6"
	"github.com/go-git/go-git/v6/plumbing"
)

type ArchisoInstallOptions struct {
	ScriptDestination string
	GitHubOwner       string
	GitHubRepository  string
	GitHubRef         string
}

type ArchisoInstaller struct {
	checkInjectability   func() (bool, error)
	packageInstalled     func(...string) (bool, error)
	download             func(string, string, os.FileMode) error
	installFromSource    func(string, string) error
	runningAsNonRootUser func() bool
}

func NewArchisoInstaller() *ArchisoInstaller {
	return &ArchisoInstaller{
		checkInjectability: archiso.CheckInjectability,
		packageInstalled:   archisoPackageInstalled,
		download: func(url, destination string, mode os.FileMode) error {
			return errors.Wrap(downloadFile(http.DefaultClient, url, destination, mode))
		},
		installFromSource: installArchisoFromSource,
		runningAsNonRootUser: func() bool {
			current, err := user.Current()
			return err == nil && current.Uid != "0"
		},
	}
}

func (s *ArchisoInstaller) Install(options ArchisoInstallOptions) error {
	if options.ScriptDestination == "" {
		return errors.New("mkarchiso script destination must not be empty")
	}
	if options.GitHubOwner == "" || options.GitHubRepository == "" || options.GitHubRef == "" {
		return errors.New("GitHub owner, repository, and ref must not be empty")
	}

	injectable, probeErr := s.checkInjectability()
	if probeErr == nil && injectable {
		return errors.New("archiso-injectable is already installed")
	}

	installed, err := s.packageInstalled("archiso", "archiso-git")
	if err != nil {
		return errors.Wrap(err)
	}
	if installed {
		slog.Info("archiso package is installed, downloading mkarchiso script directly")
		url := fmt.Sprintf(
			"https://raw.githubusercontent.com/%s/%s/%s/archiso/mkarchiso",
			options.GitHubOwner,
			options.GitHubRepository,
			options.GitHubRef,
		)
		return errors.Wrap(s.download(url, options.ScriptDestination, 0o755))
	}

	// Privilege escalation is deliberately outside this use case.
	if s.runningAsNonRootUser() {
		return errors.New("archiso package is not installed, please run this command as root to install from source")
	}
	repositoryURL := fmt.Sprintf(
		"https://github.com/%s/%s.git",
		options.GitHubOwner,
		options.GitHubRepository,
	)
	slog.Info("archiso package is not installed, installing from source", "url", repositoryURL, "ref", options.GitHubRef)
	return errors.Wrap(s.installFromSource(repositoryURL, options.GitHubRef))
}

func archisoPackageInstalled(names ...string) (bool, error) {
	if distro.GetDetail().ID() != linux.Arch.ID() {
		return false, nil
	}

	handle, err := alpm.Initialize("/", "/var/lib/pacman")
	if err != nil {
		return false, errors.Wrap(err)
	}
	defer func() {
		_ = handle.Release()
	}()

	database, err := handle.LocalDB()
	if err != nil {
		return false, errors.Wrap(err)
	}
	return database.Search(names) != nil, nil
}

func installArchisoFromSource(repositoryURL, ref string) error {
	tempDir, err := os.MkdirTemp("", "archiso-injectable-")
	if err != nil {
		return errors.Newf("failed to create source checkout directory: %w", err)
	}
	defer func() {
		_ = os.RemoveAll(tempDir)
	}()

	slog.Info("Cloning repository", "url", repositoryURL, "ref", ref)
	repository, err := git.PlainClone(tempDir, &git.CloneOptions{URL: repositoryURL})
	if err != nil {
		return errors.Newf("failed to clone %s: %w", repositoryURL, err)
	}
	worktree, err := repository.Worktree()
	if err != nil {
		return errors.Newf("failed to open repository worktree: %w", err)
	}
	if err := worktree.Checkout(&git.CheckoutOptions{
		Branch: plumbing.NewBranchReferenceName(ref),
	}); err != nil {
		return errors.Newf("failed to checkout %s: %w", ref, err)
	}

	slog.Info("Running make install", "dir", tempDir)
	command := exec.Command("make", "install-scripts")
	command.Dir = tempDir
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		return errors.Newf("make install-scripts failed: %w", err)
	}
	return nil
}

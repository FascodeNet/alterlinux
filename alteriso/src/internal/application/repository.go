package application

import (
	"net/http"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/exutils"
)

const thirdPartyRepositoryScriptURL = "https://raw.githubusercontent.com/FascodeNet/alterlinux/refs/heads/dev/alteriso/setup_3rd_repo.sh"

type RepositoryService struct {
	effectiveUserID func() int
	download        func(string, string, os.FileMode) error
	run             func(string, ...string) error
}

func NewRepositoryService() *RepositoryService {
	return &RepositoryService{
		effectiveUserID: os.Geteuid,
		download: func(url, destination string, mode os.FileMode) error {
			return errors.Wrap(downloadFile(http.DefaultClient, url, destination, mode))
		},
		run: func(name string, args ...string) error {
			return errors.Wrap(exutils.CommandWithStdio(name, args...).Run())
		},
	}
}

func (s *RepositoryService) InstallThirdPartyRepositories() error {
	// Privilege escalation is deliberately outside this use case.
	if s.effectiveUserID() != 0 {
		return errors.New("this command requires root privileges")
	}

	tempFile, err := os.CreateTemp("", "setup_3rd_repo_*.sh")
	if err != nil {
		return errors.Newf("failed to create repository setup script: %w", err)
	}
	filename := tempFile.Name()
	if err := tempFile.Close(); err != nil {
		return errors.Newf("failed to close repository setup script: %w", err)
	}
	defer func() {
		_ = os.Remove(filename)
	}()

	if err := s.download(thirdPartyRepositoryScriptURL, filename, 0o755); err != nil {
		return errors.Wrap(err)
	}
	if err := s.run("bash", filename, "-r", "all"); err != nil {
		return errors.Newf("repository setup script failed: %w", err)
	}
	return nil
}

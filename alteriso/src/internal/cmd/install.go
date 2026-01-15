package cmd

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"os/user"

	"github.com/Hayao0819/go-distro"
	"github.com/Hayao0819/go-distro/linux"

	"github.com/FascodeNet/alterlinux/src/internal/cmd/injectable"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Jguer/go-alpm/v2"
	"github.com/go-git/go-git/v6"
	"github.com/go-git/go-git/v6/plumbing"
	"github.com/spf13/cobra"
)

/*
このコードは概ねこれです。

#!/usr/bin/env bash
set -eEuo pipefail
if which pacman 2> /dev/null 1>&2 && pacman -Qq archiso; then
    curl -sL "https://raw.githubusercontent.com/FascodeNet/alterlinux/refs/heads/dev/archiso/mkarchiso" > "/usr/local/bin/mkarchiso"
else
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' 1 2 3 15
    git clone https://github.com/FascodeNet/alterlinux "$tmpdir"
    cd "$tmpdir" || exit 1
    make install
fi
*/

func isPkgInstalled(name ...string) (bool, error) {

	if !isArchLinux() {
		return false, nil
	}

	h, err := alpm.Initialize("/", "/var/lib/pacman")
	if err != nil {
		return false, err
	}
	defer h.Release()

	db, err := h.LocalDB()
	if err != nil {
		return false, err
	}

	pkg := db.Search(name)
	if pkg == nil {
		return false, nil
	}

	return true, nil
}

func downloadFile(url, dest string) error {
	res, err := http.Get(url)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	file, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = io.Copy(file, res.Body)
	if err != nil {
		return err
	}

	return nil
}

func checkoutBranch(repo *git.Repository, branch string) error {
	w, err := repo.Worktree()
	if err != nil {
		return err
	}

	err = w.Checkout(&git.CheckoutOptions{
		Branch: plumbing.NewBranchReferenceName(branch),
	})
	if err != nil {
		return err
	}

	return nil
}

func gitCloneIntoTempDir(repoURL string) (*git.Repository, string, error) {
	tempDir, err := os.MkdirTemp("", "archiso-injectable-")
	if err != nil {
		return nil, "", err
	}

	// err = gitClone(repoURL, tempDir)
	r, err := git.PlainClone(tempDir, &git.CloneOptions{
		URL: repoURL,
	})
	if err != nil {
		os.RemoveAll(tempDir)
		return nil, "", err
	}

	return r, tempDir, nil
}

func isArchLinux() bool {
	return distro.GetDetail().ID() == linux.Arch.ID()
}

func installArchisoCmd() *cobra.Command {
	cmd := cobra.Command{
		Use:   "install-archiso",
		Short: "Install injectable Archiso",
		PreRunE: func(cmd *cobra.Command, args []string) error {
			installed, err := injectable.TestInjectable()
			if err != nil {
				installed = false
			}
			if installed {
				return errors.New("archiso-injectable is already installed")
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			isArchisoInstalled, err := isPkgInstalled("archiso", "archiso-git")
			if err != nil {
				return err
			}

			githubOwner, err := cmd.Flags().GetString("github-owner")
			if err != nil {
				return err
			}

			githubRepo, err := cmd.Flags().GetString("github-repo")
			if err != nil {
				return err
			}

			githubRef, err := cmd.Flags().GetString("github-ref")
			if err != nil {
				return err
			}

			if isArchisoInstalled {
				slog.Info("archiso package is installed, downloading mkarchiso script directly")
				dest, err := cmd.Flags().GetString("script-dest")
				if err != nil {
					return err
				}

				// https://raw.githubusercontent.com/FascodeNet/alterlinux/refs/heads/dev/archiso/mkarchiso
				url := fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/%s/archiso/mkarchiso", githubOwner, githubRepo, githubRef)
				err = downloadFile(url, dest)
				if err != nil {
					return err
				}
				err = os.Chmod(dest, 0755)
				if err != nil {
					return err
				}
				return nil
			} else {
				if u, err := user.Current(); err == nil && u.Uid != "0" {
					return errors.New("archiso package is not installed, please run this command as root to install from source")
				}

				slog.Info("archiso package is not installed, cloning full repository and installing from source")
				repoURL := fmt.Sprintf("https://github.com/%s/%s.git", githubOwner, githubRepo)
				slog.Info("Cloning repository", "url", repoURL, "ref", githubRef)
				repo, tempDir, err := gitCloneIntoTempDir(repoURL)
				if err != nil {
					return err
				}
				defer os.RemoveAll(tempDir)

				slog.Info("Checking out branch", "branch", githubRef)
				if err := checkoutBranch(repo, githubRef); err != nil {
					return err
				}

				slog.Info("Running make install", "dir", tempDir)
				makeCmd := exec.Command("make", "install-scripts")
				makeCmd.Dir = tempDir
				makeCmd.Stdout = os.Stdout
				makeCmd.Stderr = os.Stderr
				if err := makeCmd.Run(); err != nil {
					return err
				}
				return nil

			}
		},
	}

	cmd.Flags().StringP("script-dest", "", "/usr/local/bin/mkarchiso", "Local destination path for the mkarchiso script")
	cmd.Flags().StringP("github-owner", "", "FascodeNet", "GitHub owner of the archiso-injectable repository")
	cmd.Flags().StringP("github-repo", "", "alterlinux", "GitHub repository name of the archiso-injectable repository")
	cmd.Flags().StringP("github-ref", "", "dev", "GitHub reference (branch, tag, commit) of the archiso-injectable repository")

	return &cmd

}

func init() {
	rootReg.Add(installArchisoCmd())
}

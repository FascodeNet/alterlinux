package cmd

import (
	"io"
	"net/http"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/exutils"
	"github.com/spf13/cobra"
)

const setupScriptUrl = "https://raw.githubusercontent.com/FascodeNet/alterlinux/refs/heads/dev/alteriso/setup_3rd_repo.sh"

// TODO: 権限昇格
func repoCmd() *cobra.Command {
	cmd := cobra.Command{
		Use:   "repo",
		Short: "Install 3rd party repositories",
		PreRunE: func(cmd *cobra.Command, args []string) error {
			// root check
			if os.Geteuid() != 0 {
				return errors.Newf("this command requires root privileges")
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			tempFile, err := os.CreateTemp("", "setup_3rd_repo_*.sh")
			if err != nil {
				return err
			}
			defer os.Remove(tempFile.Name())

			resp, err := http.Get(setupScriptUrl)
			if err != nil {
				return errors.Wrap(err)
			}
			defer resp.Body.Close()

			_, err = io.Copy(tempFile, resp.Body)
			if err != nil {
				return errors.Wrap(err)
			}

			if err := tempFile.Close(); err != nil {
				return errors.Wrap(err)
			}

			if err := os.Chmod(tempFile.Name(), 0755); err != nil {
				return errors.Wrap(err)
			}

			scriptCmd := exutils.CommandWithStdio("bash", tempFile.Name(), "-r", "all")
			if err := scriptCmd.Run(); err != nil {
				return errors.Wrap(err)
			}

			return nil

		},
	}
	return &cmd
}

func init() {
	rootReg.Add(repoCmd())
}

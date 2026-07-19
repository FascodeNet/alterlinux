package cmd

import (
	"github.com/FascodeNet/alterlinux/src/internal/application"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func repoCmd() *cobra.Command {
	installer := application.NewRepositoryService()
	return &cobra.Command{
		Use:   "repo",
		Short: "Install 3rd party repositories",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return errors.Wrap(installer.InstallThirdPartyRepositories())
		},
	}
}

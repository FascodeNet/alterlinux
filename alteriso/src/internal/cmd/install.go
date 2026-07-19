package cmd

import (
	"github.com/FascodeNet/alterlinux/src/internal/application"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func installArchisoCmd() *cobra.Command {
	installer := application.NewArchisoInstaller()
	options := application.ArchisoInstallOptions{
		ScriptDestination: "/usr/local/bin/mkarchiso",
		GitHubOwner:       "FascodeNet",
		GitHubRepository:  "alterlinux",
		GitHubRef:         "dev",
	}
	cmd := &cobra.Command{
		Use:   "install-archiso",
		Short: "Install injectable Archiso",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return errors.Wrap(installer.Install(options))
		},
	}
	cmd.Flags().StringVar(&options.ScriptDestination, "script-dest", options.ScriptDestination, "Local destination path for the mkarchiso script")
	cmd.Flags().StringVar(&options.GitHubOwner, "github-owner", options.GitHubOwner, "GitHub owner of the archiso-injectable repository")
	cmd.Flags().StringVar(&options.GitHubRepository, "github-repo", options.GitHubRepository, "GitHub repository name of the archiso-injectable repository")
	cmd.Flags().StringVar(&options.GitHubRef, "github-ref", options.GitHubRef, "GitHub reference (branch, tag, commit)")
	return cmd
}

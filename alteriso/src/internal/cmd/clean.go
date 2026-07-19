package cmd

import (
	"github.com/FascodeNet/alterlinux/src/internal/application"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func cleanCmd() *cobra.Command {
	cleaner := application.NewCleanService()
	workDir := "./work"
	cmd := &cobra.Command{
		Use:   "clean",
		Short: "Clean up working directories",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return errors.Wrap(cleaner.Clean(workDir))
		},
	}
	cmd.Flags().StringVarP(&workDir, "workdir", "w", workDir, "Path to working directory of archiso")
	return cmd
}

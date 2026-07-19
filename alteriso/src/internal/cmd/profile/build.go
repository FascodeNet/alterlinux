package profile

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func buildCmd(profileService service, options *commandOptions) *cobra.Command {
	outputDir := "./out"
	workDir := "./work"
	cmd := &cobra.Command{
		Use:   "build [config]",
		Short: "Build the ISO from a profile",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			configDir := "./configs/xfce"
			if len(args) == 1 {
				configDir = args[0]
			}
			return errors.Wrap(profileService.Build(options.input(configDir), outputDir, workDir))
		},
	}
	cmd.Flags().StringVarP(&outputDir, "out", "o", outputDir, "Output directory")
	cmd.Flags().StringVar(&workDir, "work", workDir, "Working directory")
	return cmd
}

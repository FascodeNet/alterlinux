package profile

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func generateCmd(profileService service, options *commandOptions) *cobra.Command {
	outputDir := "./out"
	cmd := &cobra.Command{
		Use:     "generate config",
		Aliases: []string{"gen"},
		Short:   "Generate an archiso profile",
		Args:    cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return errors.Wrap(profileService.Generate(options.input(args[0]), outputDir))
		},
	}
	cmd.Flags().StringVarP(&outputDir, "out", "o", outputDir, "Output directory")
	return cmd
}

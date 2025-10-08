package profile

import "github.com/spf13/cobra"

func profileFormatCmd() *cobra.Command {
	cmd := cobra.Command{
		Use:   "format config",
		Short: "Format profile config file",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			// configPath := args[0]

			return nil
		},
	}
	return &cmd
}

func init() {
	profileReg.Add(profileFormatCmd())
}

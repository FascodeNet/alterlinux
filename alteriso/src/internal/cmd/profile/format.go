package profile

import (
	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
	"github.com/spf13/cobra"
)

func profileFormatCmd() *cobra.Command {
	cmd := cobra.Command{
		Use:   "format config",
		Short: "Format profile config file",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			configPath := args[0]
			if !futils.Exists(configPath) {
				return errors.Newf("directory %s does not exist", configPath)
			}

			bootloadersPath := cmd.Parent().PersistentFlags().Lookup("bootloaders").Value.String()
			modulesPath := cmd.Parent().PersistentFlags().Lookup("modules").Value.String()

			profile, err := archiso.NewProfile(configPath, bootloadersPath, modulesPath)
			if err != nil {
				return err
			}

			if profile.Format(); err != nil {
				return errors.Wrap(err)
			}

			return nil
		},
	}
	return &cmd
}

func init() {
	profileReg.Add(profileFormatCmd())
}

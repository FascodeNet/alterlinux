package cmd

import (
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/Hayao0819/nahi/futils"
	"github.com/spf13/cobra"
)

var profileReg = cobrautils.Registory{}

func profileCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "profile",
		Short: "Manage archiso profiles",
	}
	profileReg.Bind(cmd)
	return cmd
}

func profileGenCmd() *cobra.Command {
	bootloadersPath := "/usr/share/alteriso/bootloaders"
	outDir := "./out"

	cmd := cobra.Command{
		Use:     "generate config",
		Aliases: []string{"gen"},
		Args:    cobra.ExactArgs(1),
		PreRunE: func(cmd *cobra.Command, args []string) error {
			dir := args[0]
			if !futils.Exists(dir) {
				return errors.Newf("directory %s does not exist", dir)
			}

			if err := os.MkdirAll(dir, 0o755); err != nil {
				return errors.Wrap(err)
			}

			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {

			archisoProfileDef := archiso.ArchisoProfile{
				Arch: "x86_64",
			}

			profile := archiso.ProfileDef{
				Archiso:         archisoProfileDef,
				BootloadersPath: bootloadersPath,
			}

			// fmt.Println(string(profile.ProfileDefSh()))
			profileBytes, err := profile.ProfileDefSh()
			if err != nil {
				return errors.Wrap(err)
			}

			cmd.Println(string(profileBytes))

			return nil

		},
	}

	cmd.Flags().StringVarP(&bootloadersPath, "bootloaders", "", bootloadersPath, "Path to bootloaders config dir")
	cmd.Flags().StringVarP(&outDir, "out", "o", outDir, "Output directory")
	return &cmd
}

func init() {
	profileReg.Add(profileGenCmd())
	rootReg.Add(profileCmd())
}

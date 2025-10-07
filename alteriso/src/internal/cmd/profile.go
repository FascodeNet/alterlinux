package cmd

import (
	"fmt"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/Hayao0819/nahi/cobrautils"
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

	cmd := cobra.Command{
		Use:     "generate",
		Aliases: []string{"gen"},
		// Args:    cobra.ExactArgs(1),
		PreRunE: func(cmd *cobra.Command, args []string) error {
			// dir := args[1]
			// if futils.Exists(dir) {
			// 	return fmt.Errorf("directory %s already exists", dir)
			// }

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

			fmt.Println(profile.ProfileDefSh())

			return nil

		},
	}

	cmd.Flags().StringVarP(&bootloadersPath, "bootloaders", "", bootloadersPath, "Path to bootloaders config dir")
	return &cmd
}

func init() {
	profileReg.Add(profileGenCmd())
	rootReg.Add(profileCmd())
}

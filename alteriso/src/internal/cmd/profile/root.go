package profile

import (
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/spf13/cobra"
)

var profileReg = cobrautils.Registory{}

func Cmd() *cobra.Command {
	bootloadersPath := "/usr/share/alteriso/bootloaders"
	modulesPath := "/usr/share/alteriso/modules/"

	cmd := &cobra.Command{
		Use:   "profile",
		Short: "Manage archiso profiles",
	}

	cmd.Flags().StringVarP(&modulesPath, "modules", "", modulesPath, "Path to modules config dir")
	cmd.Flags().StringVarP(&bootloadersPath, "bootloaders", "", bootloadersPath, "Path to bootloaders config dir")

	profileReg.Bind(cmd)
	return cmd
}

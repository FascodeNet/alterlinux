package profile

import (
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/spf13/cobra"
)

var profileReg = cobrautils.Registory{}

func Cmd() *cobra.Command {
	bootloadersPath := "/usr/share/alteriso/bootloaders"
	modulesPath := "/usr/share/alteriso/modules/"
	noconfirm := false

	cmd := &cobra.Command{
		Use:   "profile",
		Short: "Manage archiso profiles",
	}

	cmd.PersistentFlags().StringVarP(&modulesPath, "modules", "", modulesPath, "Path to modules config dir")
	cmd.PersistentFlags().StringVarP(&bootloadersPath, "bootloaders", "", bootloadersPath, "Path to bootloaders config dir")
	cmd.PersistentFlags().BoolVarP(&noconfirm, "noconfirm", "", noconfirm, "No check the settings before building")

	profileReg.Bind(cmd)
	return cmd
}

package profile

import (
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/spf13/cobra"
)

var profileReg = cobrautils.Registory{}

func Cmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "profile",
		Short: "Manage archiso profiles",
	}
	profileReg.Bind(cmd)
	return cmd
}

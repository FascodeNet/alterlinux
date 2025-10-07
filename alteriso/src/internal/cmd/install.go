package cmd

import (
	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/spf13/cobra"
)

func installArchisoCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "install-archiso",
		Short: "Install injectable Archiso",
		RunE: func(cmd *cobra.Command, args []string) error {
			// return errors.New("not implemented yet")
			archiso.IsInjectable()
			return nil
		},
	}
}

func init() {
	rootReg.Add(installArchisoCmd())
}

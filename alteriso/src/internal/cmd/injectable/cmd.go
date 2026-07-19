package injectable

import (
	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

func Cmd() *cobra.Command {
	return newCommand(archiso.CheckInjectability)
}

func newCommand(check func() (bool, error)) *cobra.Command {
	return &cobra.Command{
		Use:   "test-injectable",
		Short: "Test if archiso is injectable",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			injectable, err := check()
			if err != nil {
				return errors.Wrap(err)
			}
			if !injectable {
				return errors.New("archiso is not injectable")
			}
			cmd.Println("archiso is injectable")
			return nil
		},
	}
}

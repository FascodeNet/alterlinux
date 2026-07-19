package profile

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"github.com/spf13/cobra"
)

func formatCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "format config",
		Short: "Format profile config files",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return errors.Wrap(profile.ErrFormatNotImplemented)
		},
	}
}

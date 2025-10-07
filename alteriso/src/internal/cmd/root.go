package cmd

import (
	"fmt"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/spf13/cobra"
)

var rootReg = cobrautils.Registory{}

var debug bool

func rootCmd() *cobra.Command {
	root := cobra.Command{
		Use:           "alteriso",
		SilenceErrors: true,
		SilenceUsage:  true,
	}

	root.PersistentFlags().BoolVarP(&debug, "debug", "", debug, "Enable debug output")

	rootReg.Bind(&root)

	return &root
}

func Execute() error {
	if err := rootCmd().Execute(); err != nil {
		if debug {
			errors.Print(err)
		} else {
			fmt.Fprintln(os.Stderr, err.Error())
		}
		return err
	}
	return nil
}

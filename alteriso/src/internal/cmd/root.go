package cmd

import (
	"fmt"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/buildinfo"
	"github.com/FascodeNet/alterlinux/src/internal/cmd/injectable"
	profilecmd "github.com/FascodeNet/alterlinux/src/internal/cmd/profile"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/spf13/cobra"
)

var debug bool

func rootCmd() *cobra.Command {
	info := buildinfo.Current()
	root := cobra.Command{
		Use:           "alteriso",
		Version:       info.Version,
		SilenceErrors: true,
		SilenceUsage:  true,
	}

	root.PersistentFlags().BoolVarP(&debug, "debug", "", debug, "Enable debug output")
	root.AddCommand(
		profilecmd.Cmd(),
		injectable.Cmd(),
		cleanCmd(),
		installArchisoCmd(),
		repoCmd(),
	)

	return &root
}

func Execute() error {
	if err := errors.Wrap(rootCmd().Execute()); err != nil {
		if debug {
			errors.Print(err)
		} else {
			fmt.Fprintln(os.Stderr, err.Error())
		}
		return errors.Wrap(err)
	}
	return nil
}

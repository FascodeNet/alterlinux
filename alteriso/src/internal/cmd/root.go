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
	err := rootCmd().Execute()
	if err == nil {
		return nil
	}
	// tracerr で包む前に判定する。包んだあとに Is が通るかは実装依存になる
	if errors.IsReported(err) {
		return err
	}

	err = errors.Wrap(err)
	if debug {
		errors.Print(err)
	} else {
		fmt.Fprintln(os.Stderr, err.Error())
	}
	return err
}

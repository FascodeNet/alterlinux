package cmd

import (
	"github.com/Hayao0819/nahi/cobrautils"
	"github.com/spf13/cobra"
)

var rootReg = cobrautils.Registory{}

func rootCmd() *cobra.Command {
	root := cobra.Command{
		SilenceErrors: true,
		SilenceUsage:  true,
	}

	rootReg.Bind(&root)

	return &root
}

func Execute() error {
	return rootCmd().Execute()
}

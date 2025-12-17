package profile

import (
	"fmt"
	"log/slog"
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/exutils"
	"github.com/spf13/cobra"
)

func buildCmd() *cobra.Command {
	outDir := "./out"
	cmd := cobra.Command{
		Use:   "build",
		Short: "Build the ISO from generated profile",
		RunE: func(cmd *cobra.Command, args []string) error {
			configDir := args[0]
			configName := path.Base(configDir)

			bootloadersPath := cmd.Parent().PersistentFlags().Lookup("bootloaders").Value.String()
			modulesPath := cmd.Parent().PersistentFlags().Lookup("modules").Value.String()

			profile, err := archiso.NewProfile(configDir,
				archiso.WithModulesPath(modulesPath),
				archiso.WithbootloadersPath(bootloadersPath),
			)
			if err != nil {
				return err
			}

			profileDir, err := os.MkdirTemp("", fmt.Sprintf("alteriso-%s-*", configName))
			if err != nil {
				return errors.Wrap(err)
			}
			defer os.RemoveAll(profileDir)

			if err := profile.GenArchisoProfile(profileDir); err != nil {
				return errors.Wrap(err)
			}

			slog.Info("Generated archiso profile", "dir", profileDir)

			mkarchiso, err := archiso.MkarchisoPath()
			if err != nil {
				return errors.Wrap(err)
			}

			if err := exutils.CommandWithStdio(mkarchiso, "-v", "-w", "work", "-o", outDir, profileDir).Run(); err != nil {
				return errors.Wrap(err)
			}

			return nil

		},
	}

	cmd.Flags().StringVarP(&outDir, "out", "o", outDir, "Output directory")

	return &cmd

}

func init() {
	profileReg.Add(buildCmd())
}

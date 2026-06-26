package profile

import (
	"log/slog"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
	"github.com/spf13/cobra"
)

func generateCmd() *cobra.Command {

	outDir := "./out"

	cmd := cobra.Command{
		Use:     "generate config",
		Aliases: []string{"gen"},
		Args:    cobra.ExactArgs(1),
		PreRunE: func(cmd *cobra.Command, args []string) error {
			dir := args[0]

			if !futils.Exists(dir) {
				return errors.Newf("directory %s does not exist", dir)
			}

			if err := os.MkdirAll(dir, 0o755); err != nil {
				return errors.Wrap(err)
			}

			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			configDir := args[0]
			// configName := path.Base(configDir)

			bootloadersPath := cmd.Parent().PersistentFlags().Lookup("bootloaders").Value.String()
			modulesPath := cmd.Parent().PersistentFlags().Lookup("modules").Value.String()
			noConfirm := cmd.Parent().PersistentFlags().Lookup("noconfirm").Changed

			profile, err := archiso.NewProfile(configDir,
				archiso.WithModulesPath(modulesPath),
				archiso.WithbootloadersPath(bootloadersPath),
				archiso.WithNoConfirm(noConfirm),
				// archiso.WithPacmanCacheDir(pacmanCacheDir),
			)
			if err != nil {
				return err
			}

			if futils.Exists(outDir) {
				return errors.New("output directory already exists")
			}

			if err := profile.GenArchisoProfile(outDir); err != nil {
				return errors.Wrap(err)
			}

			slog.Info("Generated archiso profile", "dir", outDir)

			return nil
		},
	}
	cmd.Flags().StringVarP(&outDir, "out", "o", outDir, "Output directory")

	return &cmd
}

func init() {
	profileReg.Add(generateCmd())
}

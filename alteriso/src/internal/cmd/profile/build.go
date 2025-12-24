package profile

import (
	"log/slog"
	"os"
	"path"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/exutils"
	"github.com/spf13/cobra"
)

func getProfileFromArg(cmd *cobra.Command, configDir string) (*archiso.Profile, error) {
	bootloadersPath := cmd.Parent().PersistentFlags().Lookup("bootloaders").Value.String()
	modulesPath := cmd.Parent().PersistentFlags().Lookup("modules").Value.String()

	profile, err := archiso.NewProfile(configDir,
		archiso.WithModulesPath(modulesPath),
		archiso.WithbootloadersPath(bootloadersPath),
	)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	return profile, nil
}

func buildCmd() *cobra.Command {
	// TODO: キャッシュディレクトリを引数で指定可能にする
	outDir := "./out"
	workDir := "./work"
	cmd := cobra.Command{
		Use:   "build",
		Short: "Build the ISO from generated profile",
		PreRunE: func(cmd *cobra.Command, args []string) error {
			// TODO: 権限チェック

			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			// Load profile
			var configDir string
			if len(args) < 1 {
				configDir = "./configs/xfce"
			} else {
				configDir = args[0]
			}

			configName := path.Base(configDir)
			slog.Info("Loading profile...", "config", configDir)
			profile, err := getProfileFromArg(cmd, configDir)
			if err != nil {
				return errors.Wrap(err)
			}
			slog.Info("Using profile", "name", configName)

			// Setup directories
			for _, dir := range []*string{&outDir, &workDir} {
				absDir, err := filepath.Abs(*dir)
				if err != nil {
					return errors.Wrap(err)
				}
				*dir = absDir
				if err := os.MkdirAll(*dir, 0o755); err != nil {
					return errors.Wrap(err)
				}
			}
			slog.Info("Output directory", "dir", outDir)
			slog.Info("Working directory", "dir", workDir)

			// Generate archiso profile
			archisoprofileDir := path.Join(workDir, "profile")
			if err := profile.GenArchisoProfile(archisoprofileDir); err != nil {
				return errors.Wrap(err)
			}
			slog.Info("Generated archiso profile", "dir", archisoprofileDir)

			// Build ISO with mkarchiso
			// TODO: 権限昇格
			archisoWorkDir := path.Join(workDir, "archiso")
			if err := os.MkdirAll(archisoWorkDir, 0o755); err != nil {
				return errors.Wrap(err)
			}
			archisoPacmanCacheDir := path.Join(workDir, "pacman_cache")
			if err := os.MkdirAll(archisoPacmanCacheDir, 0o755); err != nil {
				return errors.Wrap(err)
			}
			mkarchisoPath, err := archiso.MkarchisoPath()
			if err != nil {
				return errors.Wrap(err)
			}
			mkarchisoCmd := exutils.CommandWithStdio(mkarchisoPath, "-v", "-w", archisoWorkDir, "-o", outDir, archisoprofileDir)
			mkarchisoCmd.Env = append(mkarchisoCmd.Env, "ALTERISO_PACMAN_CACHE="+archisoPacmanCacheDir)
			slog.Info("Building ISO image...", "command", mkarchisoCmd.String())

			if err := mkarchisoCmd.Run(); err != nil {
				return errors.Wrap(err)
			}

			return nil

		},
	}

	cmd.Flags().StringVarP(&outDir, "out", "o", outDir, "Output directory")
	cmd.Flags().StringVar(&workDir, "work", workDir, "Working directory")

	return &cmd

}

func init() {
	profileReg.Add(buildCmd())
}

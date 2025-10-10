package profile

import (
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/archiso"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
	"github.com/spf13/cobra"
)

func generateCmd() *cobra.Command {
	bootloadersPath := "/usr/share/alteriso/bootloaders"
	modulesPath := "/usr/share/alteriso/modules/"
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
			configName := path.Base(configDir)

			profile, err := archiso.NewProfile(configDir, bootloadersPath, modulesPath)
			if err != nil {
				return err
			}

			return profile.GenArchisoProfile(path.Join(outDir, configName))
		},
	}

	cmd.Flags().StringVarP(&modulesPath, "modules", "", modulesPath, "Path to modules config dir")
	cmd.Flags().StringVarP(&bootloadersPath, "bootloaders", "", bootloadersPath, "Path to bootloaders config dir")
	cmd.Flags().StringVarP(&outDir, "out", "o", outDir, "Output directory")
	return &cmd
}

func init() {
	profileReg.Add(generateCmd())
}

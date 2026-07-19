package profile

import (
	"github.com/FascodeNet/alterlinux/src/internal/application"
	"github.com/FascodeNet/alterlinux/src/internal/profilegen"
	"github.com/spf13/cobra"
)

type service interface {
	Generate(application.ProfileInput, string) error
	Build(application.ProfileInput, string, string) error
}

type commandOptions struct {
	modulesDir string
	generation profilegen.Options
}

func Cmd() *cobra.Command {
	return newCommand(application.NewProfileService())
}

func newCommand(profileService service) *cobra.Command {
	options := &commandOptions{
		modulesDir: "/usr/share/alteriso/modules/",
		generation: profilegen.Options{
			BootloadersDir: "/usr/share/alteriso/bootloaders",
		},
	}
	cmd := &cobra.Command{
		Use:   "profile",
		Short: "Manage archiso profiles",
	}
	cmd.PersistentFlags().StringVar(&options.modulesDir, "modules", options.modulesDir, "Path to modules config dir")
	cmd.PersistentFlags().StringVar(&options.generation.BootloadersDir, "bootloaders", options.generation.BootloadersDir, "Path to bootloaders config dir")
	cmd.PersistentFlags().BoolVar(&options.generation.NoConfirm, "noconfirm", false, "Do not confirm settings before building")
	cmd.PersistentFlags().StringVar(&options.generation.Arch, "arch", "", "Override the target architecture from profiledef.json (e.g. i686)")

	cmd.AddCommand(
		generateCmd(profileService, options),
		buildCmd(profileService, options),
		formatCmd(),
	)
	return cmd
}

func (o commandOptions) input(dir string) application.ProfileInput {
	return application.ProfileInput{
		Dir:        dir,
		ModulesDir: o.modulesDir,
		Generation: o.generation,
	}
}

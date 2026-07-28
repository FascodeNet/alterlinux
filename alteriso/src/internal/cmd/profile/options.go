// LLM Generated: Created by Claude
package profile

import (
	"fmt"
	"slices"
	"text/tabwriter"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
	"github.com/spf13/cobra"
)

func optionsCmd(profileService service, options *commandOptions) *cobra.Command {
	return &cobra.Command{
		Use:   "options config",
		Short: "List the options every loaded module declares, with their effective values",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			input, err := options.input(args[0])
			if err != nil {
				return errors.Wrap(err)
			}
			loaded, err := profileService.Load(input)
			if err != nil {
				return errors.Wrap(err)
			}

			resolved := loaded.ModuleOptions()
			writer := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)
			for _, module := range loaded.Modules() {
				for _, name := range slices.Sorted(slices.Values(lo.Keys(module.Definition.Options))) {
					spec := module.Definition.Options[name]
					value, set := resolved[module.Name][name]
					fmt.Fprintf(
						writer,
						"%s.%s\t%s\t%s\t%s\n",
						module.Name, name, spec.Type, formatOptionValue(value, set), spec.Description,
					)
				}
			}
			return errors.Wrap(writer.Flush())
		},
	}
}

// formatOptionValue renders an option that has no default and was not set as
// "-" instead of a bare nil.
func formatOptionValue(value any, set bool) string {
	if !set {
		return "-"
	}
	return fmt.Sprintf("%v", value)
}

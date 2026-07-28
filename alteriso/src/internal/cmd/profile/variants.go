// LLM Generated: Created by Claude
package profile

import (
	"fmt"
	"slices"
	"strings"
	"text/tabwriter"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
	"github.com/spf13/cobra"
)

func variantsCmd(profileService service, options *commandOptions) *cobra.Command {
	return &cobra.Command{
		Use:   "variants config",
		Short: "List the variants the profile and its modules provide",
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
			available, err := loaded.AvailableVariants()
			if err != nil {
				return errors.Wrap(err)
			}

			writer := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)
			for _, name := range slices.Sorted(slices.Values(lo.Keys(available))) {
				fmt.Fprintf(writer, "%s\t%s\n", name, strings.Join(available[name], ", "))
			}
			return errors.Wrap(writer.Flush())
		},
	}
}

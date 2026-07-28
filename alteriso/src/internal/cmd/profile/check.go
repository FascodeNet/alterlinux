// LLM Generated: Created by Claude
package profile

import (
	"fmt"
	"text/tabwriter"

	"github.com/FascodeNet/alterlinux/src/internal/application"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
	"github.com/spf13/cobra"
)

func checkCmd(profileService service, options *commandOptions) *cobra.Command {
	configsDir := "/usr/share/alteriso/configs"
	cmd := &cobra.Command{
		Use:   "check [config...]",
		Short: "Generate every profile and variant and verify that its packages resolve",
		RunE: func(cmd *cobra.Command, args []string) error {
			reports, err := profileService.Check(application.CheckInput{
				Dirs:       args,
				ConfigsDir: configsDir,
				ModulesDir: options.modulesDir,
				Generation: options.generation,
			})
			if err != nil {
				return errors.Wrap(err)
			}

			writer := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)
			for _, report := range reports {
				status, detail := "ok", ""
				if !report.OK() {
					status, detail = "FAILED", report.Err.Error()
				}
				fmt.Fprintf(writer, "%s\t%s\t%s\n", status, report.Label(), detail)
			}
			if err := writer.Flush(); err != nil {
				return errors.Wrap(err)
			}

			failed := lo.CountBy(reports, func(report application.CheckReport) bool { return !report.OK() })
			if failed > 0 {
				fmt.Fprintf(cmd.ErrOrStderr(), "%d of %d checks failed\n", failed, len(reports))
				return errors.Reported("profile check")
			}
			return nil
		},
	}
	cmd.Flags().StringVar(&configsDir, "configs", configsDir, "Directory to scan when no config is given")
	return cmd
}

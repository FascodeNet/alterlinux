package cmd

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
	"github.com/moby/sys/mount"
	"github.com/moby/sys/mountinfo"
	"github.com/spf13/cobra"
)

func correctWorkDir(dir string) (string, bool) {
	if !futils.IsDir(dir) {
		return "", false
	}

	// TODO: 適切に判断する
	return dir, true
}

func mountedDirsIn(dir string) []string {
	mounts, err := mountinfo.GetMounts(func(i *mountinfo.Info) (skip bool, stop bool) {
		mp := filepath.Clean(i.Mountpoint)
		parentDir := filepath.Clean(dir) + string(filepath.Separator)
		if mp == parentDir || strings.HasPrefix(mp+string(filepath.Separator), parentDir) {
			return false, false
		}
		return true, false
	})
	if err != nil {
		return nil
	}

	var mountedDirs []string
	for _, m := range mounts {
		mountedDirs = append(mountedDirs, m.Mountpoint)
	}
	return mountedDirs
}

func cleanCmd() *cobra.Command {
	workDir := "./work"
	cmd := cobra.Command{
		Use:   "clean",
		Short: "Clean up working directories",
		RunE: func(cmd *cobra.Command, args []string) error {

			if !futils.Exists(workDir) {
				slog.Info("Workdir does not exist, nothing to clean", "dir", workDir)
				return nil
			}

			correctedWorkDir, ok := correctWorkDir(workDir)
			if !ok {
				return errors.Newf("workdir %s is not a valid directory", workDir)
			}
			workDir = correctedWorkDir

			var failed bool
			mountedDirs := mountedDirsIn(correctedWorkDir)
			for _, dir := range mountedDirs {
				if err := mount.Unmount(dir); err != nil {
					slog.Error("Failed to unmount dir", "dir", dir, "error", err)
					failed = true
				}
			}
			if failed {
				return errors.Newf("failed to unmount some directories in %s", workDir)
			}

			slog.Info("Removing working directory...", "dir", workDir)
			if err := os.RemoveAll(workDir); err != nil {
				return err
			}
			return nil

		},
	}

	// archisoの作業ディレクトリ
	cmd.Flags().StringVarP(&workDir, "workdir", "w", workDir, "Path to working directory of archiso")

	return &cmd
}

func init() {
	rootReg.Add(cleanCmd())
}

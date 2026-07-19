package application

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/moby/sys/mount"
	"github.com/moby/sys/mountinfo"
)

type CleanService struct {
	mountedDirectories func(string) ([]string, error)
	unmount            func(string) error
	removeAll          func(string) error
}

func NewCleanService() *CleanService {
	return &CleanService{
		mountedDirectories: mountedDirectoriesUnder,
		unmount:            mount.Unmount,
		removeAll:          os.RemoveAll,
	}
}

func (s *CleanService) Clean(workDir string) error {
	if workDir == "" {
		return errors.New("working directory must not be empty")
	}
	info, err := os.Stat(workDir)
	if os.IsNotExist(err) {
		slog.Info("Workdir does not exist, nothing to clean", "dir", workDir)
		return nil
	}
	if err != nil {
		return errors.Newf("failed to inspect workdir %s: %w", workDir, err)
	}
	if !info.IsDir() {
		return errors.Newf("workdir is not a directory: %s", workDir)
	}
	workDir, err = cleanableWorkDir(workDir)
	if err != nil {
		return errors.Wrap(err)
	}

	mountedDirectories, err := s.mountedDirectories(workDir)
	if err != nil {
		return errors.Newf("failed to inspect mounts under %s: %w", workDir, err)
	}
	var unmountFailed bool
	for _, dir := range mountedDirectories {
		if err := s.unmount(dir); err != nil {
			slog.Error("Failed to unmount directory", "dir", dir, "error", errors.Wrap(err))
			unmountFailed = true
		}
	}
	if unmountFailed {
		return errors.Newf("failed to unmount some directories in %s", workDir)
	}

	slog.Info("Removing working directory", "dir", workDir)
	if err := s.removeAll(workDir); err != nil {
		return errors.Newf("failed to remove working directory %s: %w", workDir, err)
	}
	return nil
}

func cleanableWorkDir(dir string) (string, error) {
	absolute, err := filepath.Abs(dir)
	if err != nil {
		return "", errors.Newf("failed to resolve workdir %s: %w", dir, err)
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return "", errors.Newf("failed to resolve workdir symlinks %s: %w", absolute, err)
	}
	resolved = filepath.Clean(resolved)

	protected := map[string]string{filepath.Clean(string(filepath.Separator)): "filesystem root"}
	if current, err := os.Getwd(); err == nil {
		protected[filepath.Clean(current)] = "current directory"
	}
	if home, err := os.UserHomeDir(); err == nil {
		protected[filepath.Clean(home)] = "home directory"
	}
	if label, ok := protected[resolved]; ok {
		return "", errors.Newf("refusing to use %s as workdir: %s", label, resolved)
	}
	return resolved, nil
}

func mountedDirectoriesUnder(dir string) ([]string, error) {
	parent := filepath.Clean(dir)
	mounts, err := mountinfo.GetMounts(func(info *mountinfo.Info) (skip, stop bool) {
		mountpoint := filepath.Clean(info.Mountpoint)
		if mountpoint == parent || strings.HasPrefix(mountpoint, parent+string(filepath.Separator)) {
			return false, false
		}
		return true, false
	})
	if err != nil {
		return nil, errors.Wrap(err)
	}

	result := make([]string, 0, len(mounts))
	for _, mounted := range mounts {
		result = append(result, mounted.Mountpoint)
	}
	return result, nil
}

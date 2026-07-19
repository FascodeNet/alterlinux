package application

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func TestCleanServiceUnmountsBeforeRemovingWorkDir(t *testing.T) {
	workDir := filepath.Join(t.TempDir(), "work")
	if err := os.MkdirAll(workDir, 0o755); err != nil {
		t.Fatal(err)
	}

	var unmounted []string
	var removed string
	service := &CleanService{
		mountedDirectories: func(dir string) ([]string, error) {
			if dir != workDir {
				t.Errorf("mount query directory = %q, want %q", dir, workDir)
			}
			return []string{filepath.Join(workDir, "a"), filepath.Join(workDir, "b")}, nil
		},
		unmount: func(dir string) error {
			unmounted = append(unmounted, dir)
			return nil
		},
		removeAll: func(dir string) error {
			removed = dir
			return nil
		},
	}

	if err := service.Clean(workDir); err != nil {
		t.Fatalf("CleanService.Clean() error = %v", err)
	}
	wantUnmounted := []string{filepath.Join(workDir, "a"), filepath.Join(workDir, "b")}
	if !slices.Equal(unmounted, wantUnmounted) {
		t.Errorf("unmounted directories = %#v, want %#v", unmounted, wantUnmounted)
	}
	if removed != workDir {
		t.Errorf("removed directory = %q, want %q", removed, workDir)
	}
}

func TestCleanServiceRejectsFilesystemRoot(t *testing.T) {
	service := &CleanService{}
	if err := service.Clean(string(filepath.Separator)); err == nil {
		t.Fatal("CleanService.Clean() accepted the filesystem root")
	}
}

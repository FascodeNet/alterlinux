package application

import (
	"os"
	"strings"
	"testing"
)

func TestArchisoInstallerDownloadsScriptForInstalledPackage(t *testing.T) {
	var downloadedURL string
	var downloadedDestination string
	var downloadedMode os.FileMode
	installer := &ArchisoInstaller{
		checkInjectability: func() (bool, error) {
			return false, nil
		},
		packageInstalled: func(names ...string) (bool, error) {
			return true, nil
		},
		download: func(url, destination string, mode os.FileMode) error {
			downloadedURL = url
			downloadedDestination = destination
			downloadedMode = mode
			return nil
		},
	}
	options := ArchisoInstallOptions{
		ScriptDestination: "/usr/local/bin/mkarchiso",
		GitHubOwner:       "owner",
		GitHubRepository:  "repository",
		GitHubRef:         "ref",
	}

	if err := installer.Install(options); err != nil {
		t.Fatalf("ArchisoInstaller.Install() error = %v", err)
	}
	wantURL := "https://raw.githubusercontent.com/owner/repository/ref/archiso/mkarchiso"
	if downloadedURL != wantURL ||
		downloadedDestination != options.ScriptDestination ||
		downloadedMode != 0o755 {
		t.Errorf("download = (%q, %q, %o)", downloadedURL, downloadedDestination, downloadedMode)
	}
}

func TestArchisoInstallerStopsWhenInjectableArchisoExists(t *testing.T) {
	installer := &ArchisoInstaller{
		checkInjectability: func() (bool, error) {
			return true, nil
		},
		packageInstalled: func(names ...string) (bool, error) {
			t.Fatal("packageInstalled must not be called")
			return false, nil
		},
	}
	err := installer.Install(ArchisoInstallOptions{
		ScriptDestination: "/usr/local/bin/mkarchiso",
		GitHubOwner:       "owner",
		GitHubRepository:  "repository",
		GitHubRef:         "ref",
	})
	if err == nil || !strings.Contains(err.Error(), "already installed") {
		t.Fatalf("ArchisoInstaller.Install() error = %v, want already installed", err)
	}
}

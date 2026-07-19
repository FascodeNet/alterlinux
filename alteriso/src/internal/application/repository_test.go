package application

import (
	"os"
	"testing"
)

func TestRepositoryServiceCoordinatesDownloadAndExecution(t *testing.T) {
	var downloadedURL string
	var downloadedMode os.FileMode
	var commandName string
	var commandArgs []string
	service := &RepositoryService{
		effectiveUserID: func() int { return 0 },
		download: func(url, destination string, mode os.FileMode) error {
			downloadedURL = url
			downloadedMode = mode
			return nil
		},
		run: func(name string, args ...string) error {
			commandName = name
			commandArgs = append([]string(nil), args...)
			return nil
		},
	}

	if err := service.InstallThirdPartyRepositories(); err != nil {
		t.Fatalf("InstallThirdPartyRepositories() error = %v", err)
	}
	if downloadedURL != thirdPartyRepositoryScriptURL || downloadedMode != 0o755 {
		t.Errorf("download = (%q, %o)", downloadedURL, downloadedMode)
	}
	if commandName != "bash" || len(commandArgs) != 3 || commandArgs[1] != "-r" || commandArgs[2] != "all" {
		t.Errorf("command = %q %#v", commandName, commandArgs)
	}
}

func TestRepositoryServiceRequiresRoot(t *testing.T) {
	service := &RepositoryService{effectiveUserID: func() int { return 1000 }}
	if err := service.InstallThirdPartyRepositories(); err == nil {
		t.Fatal("InstallThirdPartyRepositories() succeeded for non-root user")
	}
}

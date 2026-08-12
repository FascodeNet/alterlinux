package profilegen

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func TestAURModuleBuildsRepositoryBeforePackageInstallation(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	moduleScript := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules", "aur", "base.sh"))
	root := t.TempDir()
	profileDir := filepath.Join(root, "profile")
	workDir := filepath.Join(root, "work")
	localSource := filepath.Join(profileDir, "pkgbuild", "local-package")
	fakeAyaka := filepath.Join(root, "ayaka")

	writeTestFile(t, filepath.Join(profileDir, "packages_aur.x86_64"), "aur-package\n")
	writeTestFile(t, filepath.Join(localSource, "PKGBUILD"), "pkgname=local-package\n")
	writeTestFile(t, filepath.Join(workDir, "iso.pacman.conf"), "[options]\nArchitecture = x86_64\n\n[core]\nServer = https://example.invalid/\n")
	fakeAyakaContent, err := os.ReadFile(filepath.Join("testdata", "aur", "fake-ayaka.sh"))
	if err != nil {
		t.Fatalf("failed to read fake Ayaka: %v", err)
	}
	writeTestFile(t, fakeAyaka, string(fakeAyakaContent))
	if err := os.Chmod(fakeAyaka, 0o755); err != nil {
		t.Fatalf("failed to make fake Ayaka executable: %v", err)
	}

	argsFile := filepath.Join(root, "ayaka.args")
	packagesFile := filepath.Join(root, "packages.result")
	injectedConfigFile := filepath.Join(root, "pacman.injected.conf")
	repoNameFile := filepath.Join(root, "repo.name")
	repoDirFile := filepath.Join(root, "repo.dir")
	cleanedConfigFile := filepath.Join(root, "pacman.cleaned.conf")
	command := exec.Command(
		"bash", filepath.Join("testdata", "aur", "build-packages.sh"), moduleScript, profileDir, workDir, fakeAyaka,
		argsFile, packagesFile, injectedConfigFile, repoNameFile, repoDirFile, cleanedConfigFile,
	)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("__alteriso_aur_build_packages() error = %v\n%s", err, output)
	}

	args := strings.Split(strings.TrimSpace(readTestFile(t, argsFile)), "\n")
	for _, expected := range []string{
		"build",
		"aur-package",
		"--arch",
		"x86_64",
		"--local-source",
		localSource,
		"--work-dir",
		filepath.Join(workDir, "ayaka"),
		"--makepkg-option",
		"!debug",
	} {
		if !containsString(args, expected) {
			t.Errorf("Ayaka arguments do not contain %q: %v", expected, args)
		}
	}

	if got, want := readTestFile(t, packagesFile), "base\naur-package\nlocal-package\n"; got != want {
		t.Errorf("buildmode package list = %q, want %q", got, want)
	}
	repoName := strings.TrimSpace(readTestFile(t, repoNameFile))
	if !strings.HasPrefix(repoName, "alteriso-local-") || len(strings.TrimPrefix(repoName, "alteriso-local-")) != 16 {
		t.Errorf("repository name %q does not have a random suffix", repoName)
	}
	pacmanConfig := readTestFile(t, injectedConfigFile)
	localIndex := strings.Index(pacmanConfig, "["+repoName+"]")
	coreIndex := strings.Index(pacmanConfig, "[core]")
	if localIndex < 0 || coreIndex < 0 || localIndex > coreIndex {
		t.Errorf("local repository is not before core repository:\n%s", pacmanConfig)
	}
	repoDir := strings.TrimSpace(readTestFile(t, repoDirFile))
	if !strings.Contains(pacmanConfig, "Server = file://"+repoDir) {
		t.Errorf("local repository server is missing:\n%s", pacmanConfig)
	}
	if _, err := os.Stat(repoDir); !os.IsNotExist(err) {
		t.Errorf("temporary repository was not removed: %v", err)
	}
	for _, path := range []string{repoDir + ".lock", filepath.Join(workDir, repoName+"-iso-x86_64.json.lock")} {
		if _, err := os.Stat(path); !os.IsNotExist(err) {
			t.Errorf("temporary lock was not removed at %s: %v", path, err)
		}
	}
	if got, want := readTestFile(t, cleanedConfigFile), "[options]\nArchitecture = x86_64\n\n[core]\nServer = https://example.invalid/\n"; got != want {
		t.Errorf("pacman config after cleanup = %q, want %q", got, want)
	}
}

func TestAURModuleCleansUpBuildFailures(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	moduleScript := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules", "aur", "base.sh"))

	for _, mode := range []string{"failure", "invalid-manifest", "external-database"} {
		t.Run(mode, func(t *testing.T) {
			root := t.TempDir()
			profileDir := filepath.Join(root, "profile")
			workDir := filepath.Join(root, "work")
			fakeAyaka := filepath.Join(root, "ayaka")
			writeTestFile(t, filepath.Join(profileDir, "packages_aur.x86_64"), "aur-package\n")
			originalConfig := "[options]\nArchitecture = x86_64\n\n[core]\nServer = https://example.invalid/\n"
			writeTestFile(t, filepath.Join(workDir, "iso.pacman.conf"), originalConfig)
			fakeAyakaContent, err := os.ReadFile(filepath.Join("testdata", "aur", "fake-ayaka.sh"))
			if err != nil {
				t.Fatalf("failed to read fake Ayaka: %v", err)
			}
			writeTestFile(t, fakeAyaka, string(fakeAyakaContent))
			if err := os.Chmod(fakeAyaka, 0o755); err != nil {
				t.Fatalf("failed to make fake Ayaka executable: %v", err)
			}

			command := exec.Command("bash", filepath.Join("testdata", "aur", "build-failure.sh"), moduleScript, profileDir, workDir, fakeAyaka, filepath.Join(root, "ayaka.args"))
			command.Env = append(os.Environ(), "AYAKA_MODE="+mode, "AYAKA_EXTERNAL_DATABASE="+filepath.Join(root, "outside.db"))
			if output, err := command.CombinedOutput(); err == nil {
				t.Fatalf("AUR build in mode %s succeeded, want error\n%s", mode, output)
			}
			if got := readTestFile(t, filepath.Join(workDir, "iso.pacman.conf")); got != originalConfig {
				t.Errorf("pacman config after failure = %q, want %q", got, originalConfig)
			}
			matches, err := filepath.Glob(filepath.Join(workDir, "alteriso-local-*"))
			if err != nil {
				t.Fatal(err)
			}
			if len(matches) != 0 {
				t.Errorf("temporary AUR files remain: %v", matches)
			}
		})
	}
}

func TestAURModuleUsesBootstrapAURPackageList(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	moduleScript := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules", "aur", "base.sh"))
	root := t.TempDir()
	profileDir := filepath.Join(root, "profile")
	workDir := filepath.Join(root, "work")
	fakeAyaka := filepath.Join(root, "ayaka")
	writeTestFile(t, filepath.Join(profileDir, "packages_aur.x86_64"), "iso-only\n")
	writeTestFile(t, filepath.Join(profileDir, "bootstrap_packages_aur.x86_64"), "bootstrap-only\n")
	writeTestFile(t, filepath.Join(workDir, "bootstrap.pacman.conf"), "[options]\nArchitecture = x86_64\n")
	fakeAyakaContent, err := os.ReadFile(filepath.Join("testdata", "aur", "fake-ayaka.sh"))
	if err != nil {
		t.Fatal(err)
	}
	writeTestFile(t, fakeAyaka, string(fakeAyakaContent))
	if err := os.Chmod(fakeAyaka, 0o755); err != nil {
		t.Fatal(err)
	}
	argsFile := filepath.Join(root, "ayaka.args")
	command := exec.Command(
		"bash", filepath.Join("testdata", "aur", "build-packages.sh"), moduleScript, profileDir, workDir, fakeAyaka,
		argsFile, filepath.Join(root, "packages.result"), filepath.Join(root, "pacman.injected.conf"),
		filepath.Join(root, "repo.name"), filepath.Join(root, "repo.dir"), filepath.Join(root, "pacman.cleaned.conf"),
	)
	command.Env = append(os.Environ(), "BUILD_MODE=bootstrap")
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("bootstrap AUR build error = %v\n%s", err, output)
	}
	args := strings.Split(strings.TrimSpace(readTestFile(t, argsFile)), "\n")
	if !containsString(args, "bootstrap-only") || containsString(args, "iso-only") {
		t.Errorf("Ayaka bootstrap arguments = %v", args)
	}
}

func TestAURModuleRemovesPreBuildLockAfterLaterFailure(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	moduleScript := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules", "aur", "base.sh"))
	workDir := t.TempDir()
	command := exec.Command("bash", filepath.Join("testdata", "aur", "cleanup-on-failure.sh"), moduleScript, workDir)
	if output, err := command.CombinedOutput(); err == nil {
		t.Fatalf("failure harness succeeded, want error\n%s", output)
	}
	if _, err := os.Stat(filepath.Join(workDir, "base.pre__make_packages")); !os.IsNotExist(err) {
		t.Errorf("pre-build lock remains after failure: %v", err)
	}
}

func TestAURModuleValidationOnlyRequiresAyakaForBuildInputs(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	moduleScript := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", "..", "modules", "aur", "base.sh"))

	for _, test := range []struct {
		name      string
		withInput bool
		wantError bool
	}{
		{name: "unused module"},
		{name: "empty generated list"},
		{name: "missing Ayaka", withInput: true, wantError: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			profileDir := t.TempDir()
			if test.withInput {
				writeTestFile(t, filepath.Join(profileDir, "packages_aur.x86_64"), "aur-package\n")
			} else if test.name == "empty generated list" {
				writeTestFile(t, filepath.Join(profileDir, "packages_aur.x86_64"), "\n")
			}
			command := exec.Command("bash", filepath.Join("testdata", "aur", "validate.sh"), moduleScript, profileDir)
			output, err := command.CombinedOutput()
			if test.wantError && err == nil {
				t.Fatalf("__alteriso_aur_validate() succeeded, want error")
			}
			if !test.wantError && err != nil {
				t.Fatalf("__alteriso_aur_validate() error = %v\n%s", err, output)
			}
		})
	}
}

func TestAURModuleRegistersValidationBeforeProfileValidationRuns(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("failed to locate test source")
	}
	projectDir := filepath.Clean(filepath.Join(filepath.Dir(filename), "..", "..", ".."))
	profileDir := t.TempDir()
	writeTestFile(t, filepath.Join(profileDir, "profiledef.json"), `{"arch":"x86_64","modules":["aur"]}`)
	writeTestFile(t, filepath.Join(profileDir, "profiledef.sh"), "#!/usr/bin/env bash\n")

	loaded, err := profile.Load(profileDir, filepath.Join(projectDir, "modules"))
	if err != nil {
		t.Fatalf("profile.Load() error = %v", err)
	}
	rendered, err := renderProfileDefinition(loaded, Options{})
	if err != nil {
		t.Fatalf("renderProfileDefinition() error = %v", err)
	}
	definition := string(rendered)
	registration := strings.Index(definition, "__alteriso_add_validator __alteriso_aur_validate")
	validation := strings.LastIndex(definition, "\n__alteriso_validate\n")
	if registration < 0 || validation < 0 || registration > validation {
		t.Errorf("AUR validator is not registered before profile validation")
	}
}

func containsString(items []string, expected string) bool {
	for _, item := range items {
		if item == expected {
			return true
		}
	}
	return false
}

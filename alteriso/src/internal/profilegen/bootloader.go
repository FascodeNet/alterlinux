package profilegen

import (
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
)

func kernelParameters(modules []profile.Module) string {
	var parameters []string
	for _, module := range modules {
		parameters = append(parameters, module.Definition.AppendKernelParam...)
	}
	return strings.Join(uniqueStrings(parameters), " ")
}

func generateBootloaderConfigs(loaded *profile.Profile, outDir string, options Options) error {
	entries, err := os.ReadDir(options.BootloadersDir)
	if err != nil {
		return errors.Newf("failed to read bootloaders directory: %w", err)
	}

	values := map[string]string{
		"ALTERISO_KERNEL_NAME":   loaded.Definition.KernelName,
		"ALTERISO_OS_NAME":       loaded.Definition.OSName,
		"ALTERISO_COW_SPACESIZE": loaded.Definition.COWSpaceSize,
		"ALTERISO_KERNEL_PARAM":  kernelParameters(loaded.Modules()),
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		source := filepath.Join(options.BootloadersDir, entry.Name())
		if override := filepath.Join(loaded.Dir, entry.Name()); pathExists(override, directory) {
			source = override
		}
		if err := copyDirWithValues(source, filepath.Join(outDir, entry.Name()), values); err != nil {
			return errors.Wrap(err)
		}
	}
	return nil
}

func copyDirWithValues(sourceDir, destinationDir string, values map[string]string) error {
	sourceInfo, err := os.Stat(sourceDir)
	if err != nil {
		return errors.Newf("failed to access source directory %s: %w", sourceDir, err)
	}
	if !sourceInfo.IsDir() {
		return errors.Newf("source path is not a directory: %s", sourceDir)
	}
	if err := os.MkdirAll(destinationDir, sourceInfo.Mode()); err != nil {
		return errors.Newf("failed to create destination directory %s: %w", destinationDir, err)
	}

	entries, err := os.ReadDir(sourceDir)
	if err != nil {
		return errors.Newf("failed to read source directory %s: %w", sourceDir, err)
	}
	for _, entry := range entries {
		source := filepath.Join(sourceDir, entry.Name())
		destination := filepath.Join(destinationDir, entry.Name())
		if entry.IsDir() {
			if err := copyDirWithValues(source, destination, values); err != nil {
				return errors.Wrap(err)
			}
			continue
		}
		if err := copyFileWithValues(source, destination, values); err != nil {
			return errors.Wrap(err)
		}
	}
	return nil
}

func copyFileWithValues(source, destination string, values map[string]string) error {
	sourceFile, err := os.Open(source)
	if err != nil {
		return errors.Newf("failed to open source file %s: %w", source, err)
	}
	defer func() {
		_ = sourceFile.Close()
	}()

	content, err := io.ReadAll(sourceFile)
	if err != nil {
		return errors.Newf("failed to read source file %s: %w", source, err)
	}
	rendered := string(content)
	for key, value := range values {
		rendered = strings.ReplaceAll(rendered, "%"+key+"%", value)
	}

	info, err := sourceFile.Stat()
	if err != nil {
		return errors.Newf("failed to stat source file %s: %w", source, err)
	}
	if err := os.WriteFile(destination, []byte(rendered), info.Mode()); err != nil {
		return errors.Newf("failed to write destination file %s: %w", destination, err)
	}
	return nil
}

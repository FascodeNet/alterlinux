package archiso

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

//go:embed modules/*
var archisoModules embed.FS

func moduleNames() []string {
	entries, err := archisoModules.ReadDir("modules")
	if err != nil {
		return []string{}
	}

	return lo.FilterMap(entries, func(item fs.DirEntry, index int) (string, bool) {
		return item.Name(), item.IsDir()
	})
}

func moduleFS(name string) (fs.FS, error) {
	sub, err := fs.Sub(archisoModules, "modules/"+name)
	if err != nil {
		return nil, errors.Wrap(err)
	}
	return sub, nil
}

// func Files(names []string, file string) ([]string, error) {
// 	paths := []string{}
// 	for _, name := range names {
// 		sub, err := ModuleFS(name)
// 		if err != nil {
// 			return nil, errors.Wrap(err)
// 		}
// 		entries, err := fs.Glob(sub, file)
// 		if err != nil {
// 			return nil, errors.Wrap(err)
// 		}
// 		paths = append(paths, lo.Map(entries, func(item string, index int) string {
// 			return name + "/" + item
// 		})...)
// 	}
// 	return paths, nil
// }

func moduleFile(module string, file string) ([]byte, error) {
	sub, err := moduleFS(module)
	if err != nil {
		return nil, errors.Wrap(err)
	}
	bytes, err := fs.ReadFile(sub, file)
	if err != nil {
		return nil, errors.Wrap(err)
	}
	return bytes, nil
}
func exportModuleDir(module, target, out string) error {
	sub, err := moduleFS(module)
	if err != nil {
		return errors.Wrap(err)
	}
	entries, err := fs.Glob(sub, target+"/*")
	if err != nil {
		return errors.Wrap(err)
	}
	for _, entry := range entries {
		bytes, err := fs.ReadFile(sub, entry)
		if err != nil {
			return errors.Wrap(err)
		}
		path := out + "/" + entry[len(target)+1:]
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return errors.Wrap(err)
		}
		if err := os.WriteFile(path, bytes, 0o644); err != nil {
			return errors.Wrap(err)
		}
	}
	return nil
}

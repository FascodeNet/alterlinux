package archiso

import (
	"os"
	"path"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/utils"
	"github.com/Hayao0819/nahi/futils"
	"github.com/samber/lo"
)

func kernelParam(m []Module) string {
	params := []string{}
	for _, mod := range m {
		params = append(params, mod.Config.Appendkernelparam...)
	}
	return strings.Join(lo.Uniq(params), " ")
}

func (p *Profile) generateBootloaderConfigs(outDir string) error {
	dirs, err := os.ReadDir(p.BootloadersPath)
	if err != nil {
		return errors.Wrap(err)
	}

	copyTargets := lo.FilterMap(dirs, func(item os.DirEntry, index int) (string, bool) {
		override_dir := path.Join(p.Path, item.Name())
		if futils.IsDir(override_dir) {
			return override_dir, true
		}
		return path.Join(p.BootloadersPath, item.Name()), item.IsDir()
	})

	kv := map[string]string{
		"ALTERISO_KERNEL_NAME":   p.Config.KernelName,
		"ALTERISO_OS_NAME":       p.Config.OSName,
		"ALTERISO_COW_SPACESIZE": p.Config.COWSpaceSize,
		"ALTERISO_KERNEL_PARAM":  kernelParam(p.Modules()),
	}

	for _, item := range copyTargets {
		dst := path.Join(outDir, path.Base(item))
		if err := utils.CopyDirWithKV(item, dst, kv); err != nil {
			return errors.Wrap(err)
		}
	}

	return nil
}

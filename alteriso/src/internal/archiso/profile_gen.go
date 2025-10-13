package archiso

import (
	"encoding/json"
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/utils"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/futils"
	"github.com/samber/lo"

	cp "github.com/otiai10/copy"
)

func (p *Profile) generateBootloaderConfigs(outDir string) error {
	dirs, err := os.ReadDir(p.BootloadersPath)
	if err != nil {
		return errors.Wrap(err)
	}

	copyTargets := lo.FilterMap(dirs, func(item os.DirEntry, index int) (string, bool) {
		return path.Join(p.BootloadersPath, item.Name()), item.IsDir()
	})

	// tasks := lo.Map(copyTargets, func(item os.DirEntry, index int) cputils.CopyTask {
	// 	// slog.Info("Copying bootloader", "source", item.Name(), "dest", bootloadersDst)
	// 	return cputils.CopyTask{
	// 		Source: path.Join(p.BootloadersPath, item.Name()),
	// 		Dest:   path.Join(bootloadersDst, item.Name()),
	// 	}
	// })

	// return errors.Wrap(cputils.CopyAll(tasks...))

	kv := map[string]string{
		"ALTERISO_KERNEL_NAME": p.Config.KernelName,
		"ALTERISO_OS_NAME":     p.Config.OSName,
        "ALTERISO_COW_SPACESIZE": p.Config.COWSpaceSize,
	}

	for _, item := range copyTargets {
		dst := path.Join(outDir, path.Base(item))
		if err := utils.CopyDirWithKV(item, dst, kv); err != nil {
			return errors.Wrap(err)
		}
	}

	return nil
}

func (p *Profile) pacmanConf(outDir string) error {
	dst := path.Join(outDir, "pacman.conf")
	src := path.Join(p.Path, "pacman.conf")
	if !futils.Exists(src) {
		return errors.Newf("pacman.conf file does not exist in %s", p.Path)
	}

	return errors.Wrap(cputils.CopyAll(cputils.CopyTask{
		Source: src,
		Dest:   dst,
	}))
}

func (p *Profile) copyInjecter(outDir string) error {
	dst := path.Join(outDir, "injecter.sh")

	bytes, err := injecter()
	if err != nil {
		return errors.Wrap(err)
	}

	if err := os.WriteFile(dst, bytes, 0o644); err != nil {
		return errors.Wrap(err)
	}
	return nil
}

func (p *Profile) generateProfileDefSh(outDir string) error {
	profileDefSh, err := p.ProfileDefSh()
	if err != nil {
		return errors.Wrap(err)
	}
	if err := os.WriteFile(path.Join(outDir, "profiledef.sh"), profileDefSh, 0o644); err != nil {
		return errors.Wrap(err)
	}

	alterisoConfigBytes, err := json.Marshal(p.Config)
	if err != nil {
		return errors.Wrap(err)
	}
	if err := os.WriteFile(path.Join(outDir, "profiledef.json"), alterisoConfigBytes, 0o644); err != nil {
		return errors.Wrap(err)
	}
	return nil
}

func (p *Profile) GenArchisoProfile(outDir string) error {
	tempDir, err := os.MkdirTemp(os.TempDir(), "alteriso-*")
	defer func() {
		_ = os.RemoveAll(tempDir)
	}()
	if err != nil {
		return errors.Wrap(err)
	}

	tasks := []func(outDir string) error{
		p.generateBootloaderConfigs,
		p.generateProfileDefSh,
		p.copyInjecter,
		p.copyAirootfs,
		p.generatePackagesFile,
		p.pacmanConf,
	}

	for _, task := range tasks {
		if err := task(tempDir); err != nil {
			return err
		}
	}

	if err := cp.Copy(tempDir, outDir); err != nil {
		return errors.Wrap(err)
	}

	return nil
}

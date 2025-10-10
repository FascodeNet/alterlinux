package archiso

import (
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/futils"
	"github.com/samber/lo"
)

func (p *Profile) copyBootloaders(outDir string) error {
	bootloadersDst := path.Join(outDir)

	dirs, err := os.ReadDir(p.BootloadersPath)
	if err != nil {
		return errors.Wrap(err)
	}

	copyTargets := lo.Filter(dirs, func(item os.DirEntry, index int) bool {
		return item.IsDir()
	})

	tasks := lo.Map(copyTargets, func(item os.DirEntry, index int) cputils.CopyTask {
		// slog.Info("Copying bootloader", "source", item.Name(), "dest", bootloadersDst)
		return cputils.CopyTask{
			Source: path.Join(p.BootloadersPath, item.Name()),
			Dest:   path.Join(bootloadersDst, item.Name()),
		}
	})

	return errors.Wrap(cputils.CopyAll(tasks...))
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
	return nil
}

func (p *Profile) GenArchisoProfile(outDir string) error {
	// tempDir, err := os.MkdirTemp(os.TempDir(), "alteriso-*")
	// defer func() {
	// 	_ = os.RemoveAll(tempDir)
	// }()
	// if err != nil {
	// 	return errors.Wrap(err)
	// }

	tasks := []func(outDir string) error{
		p.copyBootloaders,
		p.generateProfileDefSh,
		p.copyInjecter,
		p.copyAirootfs,
		p.generatePackagesFile,
		p.pacmanConf,
	}

	for _, task := range tasks {
		if err := task(outDir); err != nil {
			return err
		}
	}
	return nil
}

package archiso

import (
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/futils"
	cp "github.com/otiai10/copy"
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

func (p *Profile) copyPackages(outDir string) error {
	dst := path.Join(outDir, "packages.x86_64")
	src := path.Join(p.ConfigPath, "packages.x86_64")
	if !futils.Exists(src) {
		return errors.Newf("packages.x86_64 file does not exist in %s", p.ConfigPath)
	}

	baseDst := path.Join(outDir, "bootstrap_packages.x86_64")
	baseSrc := path.Join(p.ConfigPath, "bootstrap_packages.x86_64")
	if !futils.Exists(baseSrc) {
		return errors.Newf("bootstrap_packages.x86_64 file does not exist in %s", p.ConfigPath)
	}

	tasks := []cputils.CopyTask{
		{
			Source: src,
			Dest:   dst,
		},
		{
			Source: baseSrc,
			Dest:   baseDst,
		},
	}

	return errors.Wrap(cputils.CopyAll(tasks...))
}

func (p *Profile) pacmanConf(outDir string) error {
	dst := path.Join(outDir, "pacman.conf")
	src := path.Join(p.ConfigPath, "pacman.conf")
	if !futils.Exists(src) {
		return errors.Newf("pacman.conf file does not exist in %s", p.ConfigPath)
	}

	return errors.Wrap(cputils.CopyAll(cputils.CopyTask{
		Source: src,
		Dest:   dst,
	}))
}

func (p *Profile) copyAirootfs(outDir string) error {
	dst := path.Join(outDir, "airootfs")

	src := path.Join(p.ConfigPath, "airootfs")
	if !futils.Exists(src) {
		return errors.Newf("airootfs directory does not exist in %s", p.ConfigPath)
	}

	return cp.Copy(src, dst)
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
		p.copyPackages,
		p.pacmanConf,
	}

	for _, task := range tasks {
		if err := task(outDir); err != nil {
			return err
		}
	}
	return nil
}

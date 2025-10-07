package archiso

import (
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
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

func (p *Profile) GenArchisoProfile(outDir string) error {
	// tempDir, err := os.MkdirTemp(os.TempDir(), "alteriso-*")
	// defer func() {
	// 	_ = os.RemoveAll(tempDir)
	// }()
	// if err != nil {
	// 	return errors.Wrap(err)
	// }

	if err := p.copyBootloaders(outDir); err != nil {
		return err
	}
	profileDefSh, err := p.ProfileDefSh()
	if err != nil {
		return err
	}
	if err := os.WriteFile(path.Join(outDir, "profiledef.sh"), profileDefSh, 0o644); err != nil {
		return errors.Wrap(err)
	}
	return nil
}

package archiso

import (
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
)

func (p *Profile) copyBootloaders(outDir string) error {
	bootloadersDst := path.Join(outDir, "bootloaders")
	cptask := cputils.CopyTask{
		Source: p.BootloadersPath,
		Dest:   bootloadersDst,
	}
	if err := cptask.Copy(); err != nil {
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

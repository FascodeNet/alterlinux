package archiso

import (
	"encoding/json"
	"os"
	"path"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/futils"

	cp "github.com/otiai10/copy"
)

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

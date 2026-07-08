package archiso

import (
	"encoding/json"
	"log/slog"
	"os"
	"path"
	"path/filepath"
	"reflect"
	"runtime"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/futils"

	cp "github.com/otiai10/copy"
)

func (p *Profile) PacmanConf() string {
	if p.Config.PacmanConf != "" {
		base := p.Config.PacmanConf
		if !filepath.IsAbs(base) {
			base = path.Join(p.Path, base)
		}
		if archV := base + "." + p.Config.Arch; futils.Exists(archV) {
			return archV
		}
		return base
	}
	if archV := path.Join(p.Path, "pacman.conf."+p.Config.Arch); futils.Exists(archV) {
		return archV
	}
	return path.Join(p.Path, "pacman.conf")
}

func (p *Profile) copyPacmanConf(outDir string) error {
	dst := path.Join(outDir, "pacman.conf")
	src := p.PacmanConf()
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

func (p *Profile) copySplashImage(outDir string) error {
	if futils.Exists(path.Join(p.Path, "splash.png")) {
		src := path.Join(p.Path, "splash.png")
		dsts := []string{
			path.Join(outDir, "syslinux", "splash.png"),
		}
		for _, dst := range dsts {
			if futils.Exists(dst) {
				if err := os.Remove(dst); err != nil {
					return errors.Wrap(err)
				}
			}
			if err := cp.Copy(src, dst); err != nil {
				return errors.Wrap(err)
			}
		}
	}
	return nil
}

func funcName(i interface{}) string {
	v := reflect.ValueOf(i)
	p := v.Pointer()

	return runtime.FuncForPC(p).Name()
}

func (p *Profile) GenArchisoProfile(outDir string) error {
	tempDir, err := os.MkdirTemp(os.TempDir(), "alteriso-*")
	defer os.RemoveAll(tempDir)
	if err != nil {
		return errors.Wrap(err)
	}

	tasks := []func(outDir string) error{
		p.generateBootloaderConfigs,
		p.copySplashImage,
		p.generateProfileDefSh,
		p.copyInjecter,
		p.copyAirootfs,
		p.generatePackagesFile,
		p.copyPacmanConf,
		p.generateInfoFile,
	}

	for _, task := range tasks {
		if err := task(tempDir); err != nil {
			slog.Error("Failed to execute task", "task", funcName(task), "error", err)
			return errors.Wrap(err)
		}
	}

	if err := cp.Copy(tempDir, outDir); err != nil {
		return errors.Wrap(err)
	}

	return nil
}

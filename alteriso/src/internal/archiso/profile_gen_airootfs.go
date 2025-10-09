package archiso

import (
	"log/slog"
	"path"

	"github.com/Hayao0819/nahi/futils"
	cp "github.com/otiai10/copy"
)

func (p *Profile) copyAirootfs(outDir string) error {
	dst := path.Join(outDir, "airootfs")

	slog.Info("modules", "list", p.Archiso.modules)
	slog.Info("Copying airootfs", "dest", dst)

	srcdirs := []string{}

	for _, modName := range p.Modules() {
		srcdirs = append(srcdirs,
			path.Join(p.ModulesPath, modName.Name, "airootfs.any"),
			path.Join(p.ModulesPath, modName.Name, "airootfs."+p.Archiso.Arch),
		)
	}

	srcdirs = append(srcdirs,
		path.Join(p.ConfigPath, "airootfs.any"),
		path.Join(p.ConfigPath, "airootfs."+p.Archiso.Arch),
	)

	for _, src := range srcdirs {
		if !futils.Exists(src) {
			// return errors.Newf("airootfs directory does not exist in %s", p.ConfigPath)
			slog.Warn("airootfs directory does not exist", "source", src)
			continue
		}
		slog.Info("Copying airootfs from profile", "source", src, "dest", dst)
		if err := cp.Copy(src, dst); err != nil {
			// return errors.Wrap(err)
			slog.Warn("Failed to copy airootfs from profile", "source", src, "dest", dst, "error", err)
		}
	}
	return nil
}

package archiso

import (
	"log/slog"
	"path"

	"github.com/Hayao0819/nahi/futils"
	cp "github.com/otiai10/copy"
	"github.com/samber/lo"
)

func (p *Profile) copyAirootfs(outDir string) error {
	dst := path.Join(outDir, "airootfs")

	lo.ForEach(p.Archiso.modules, func(mname string, index int) {
		if err := exportModuleDir(mname, "airootfs.any", dst); err != nil {
			slog.Warn("Failed to export module airootfs.any", "module", mname, "error", err)
			return
		}

		if err := exportModuleDir(mname, "airootfs."+p.Archiso.Arch, dst); err != nil {
			slog.Warn("Failed to export module airootfs."+p.Archiso.Arch, "module", mname, "error", err)
			return
		}
	})

	srcdirs := []string{
		path.Join(p.ConfigPath, "airootfs.any"),
		path.Join(p.ConfigPath, "airootfs."+p.Archiso.Arch),
	}

	for _, src := range srcdirs {
		if !futils.Exists(src) {
			// return errors.Newf("airootfs directory does not exist in %s", p.ConfigPath)
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

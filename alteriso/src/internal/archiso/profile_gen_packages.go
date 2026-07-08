package archiso

import (
	"log/slog"
	"os"
	"path"
	"sort"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/futils"
	"github.com/samber/lo"
)

func (p *Profile) Packages(filename string) ([]string, error) {

	srcdirs := []string{
		p.Path,
	}

	for _, m := range p.Modules() {
		srcdirs = append(srcdirs, m.Path)
	}

	files := []string{}
	for _, d := range srcdirs {
		file := path.Join(d, filename)
		filedir := file + ".d"
		if futils.Exists(filedir) {
			entries, err := os.ReadDir(filedir)
			if err != nil {
				slog.Warn("failed to read packages dir", "dir", filedir, "error", err)
				continue
			}
			for _, entry := range entries {
				if entry.IsDir() {
					continue
				}
				files = append(files, path.Join(filedir, entry.Name()))
			}
		}
		files = append(files, file)
	}

	pkgs := []string{}
	for _, f := range files {
		if !futils.Exists(f) {
			continue
		}
		slog.Info("Loading packages file", "file", f)
		content, err := futils.ReadFileLine(f)
		if err != nil {
			return nil, errors.Wrap(err)
		}
		pkgs = append(pkgs, content...)
	}

	pkgs = lo.Filter(pkgs, func(item string, index int) bool {
		nospace := strings.TrimSpace(item)
		return len(nospace) != 0 && !strings.HasPrefix(nospace, "#")
	})
	pkgs = lo.Uniq(pkgs)
	sort.Strings(pkgs)

	return pkgs, nil
}

func (p *Profile) generatePackagesFile(outDir string) error {
	arch := p.Config.Arch
	for _, base := range []string{"packages", "bootstrap_packages"} {
		shared, err := p.Packages(base)
		if err != nil {
			return errors.Wrap(err)
		}
		archSpecific, err := p.Packages(base + "." + arch)
		if err != nil {
			return errors.Wrap(err)
		}
		pkgs := lo.Uniq(append(shared, archSpecific...))
		sort.Strings(pkgs)

		dst := path.Join(outDir, base+"."+arch)
		content := strings.Join(pkgs, "\n") + "\n"
		if err := os.WriteFile(dst, []byte(content), 0o644); err != nil {
			return errors.Wrap(err)
		}
	}
	return nil
}

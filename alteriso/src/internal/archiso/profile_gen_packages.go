package archiso

import (
	"os"
	"path"
	"sort"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/cputils"
	"github.com/Hayao0819/nahi/flist"
	"github.com/Hayao0819/nahi/futils"
	"github.com/samber/lo"
)

func (p *Profile) Packages(filename string) ([]string, error) {
	src := path.Join(p.ConfigPath, filename)
	srcdir := path.Join(p.ConfigPath, filename+".d")

	files := []string{src}
	if futils.Exists(srcdir) {
		dirFiles, err := flist.Get(srcdir, flist.WithFileOnly(), flist.WithExactDepth(1))
		if err != nil {
			return nil, errors.Wrap(err)
		}
		files = append(files, *dirFiles...)
	}
	pkgs := []string{}
	for _, f := range files {
		if !futils.Exists(f) {
			continue
		}
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

func (p *Profile) generatePackagesFile(outDir string) error {
	for _, filename := range []string{"packages.x86_64", "bootstrap_packages.x86_64"} {
		pkgs, err := p.Packages(filename)
		if err != nil {
			return errors.Wrap(err)
		}
		dst := path.Join(outDir, filename)
		content := strings.Join(pkgs, "\n") + "\n"
		if err := os.WriteFile(dst, []byte(content), 0o644); err != nil {
			return errors.Wrap(err)
		}
	}
	return nil
}

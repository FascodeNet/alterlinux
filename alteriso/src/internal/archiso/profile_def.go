package archiso

import (
	"bytes"
	"os"
	"path"
	"text/template"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/pkg/shutils"
	"github.com/Hayao0819/nahi/tputils"
	"github.com/samber/lo"
	"mvdan.cc/sh/v3/syntax"
)

func stripShebangBytes(data []byte) ([]byte, error) {
	ast, err := shutils.ParseBytes(data, "")
	if err != nil {
		return data, err
	}
	ast = shutils.StripShebang(ast).(*syntax.File)
	buf, err := shutils.ToBytes(ast)
	if err != nil {
		return data, err
	}
	return bytes.TrimSpace(buf), nil
}

func (p *Profile) ProfileDefSh() ([]byte, error) {
	loaderContent, err := loader()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	loaderContent, err = stripShebangBytes(loaderContent)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	profileDef, err := os.ReadFile(p.Path + "/profiledef.sh")
	if err != nil {
		return nil, errors.Wrap(err)
	}

	embedScripts := []string{}
	for _, module := range p.Modules() {
		scrips := module.Config.LoadScripts
		embedScripts = append(embedScripts, lo.Map(scrips, func(item string, index int) string {
			return path.Join(module.Path, item)
		})...)
	}

	injects := map[string][]string{}

	for _, module := range p.Modules() {
		for fname, code := range module.Config.Injects {
			if _, ok := injects[fname]; !ok {
				injects[fname] = []string{}
			}
			injects[fname] = append(injects[fname], code...)
		}
	}

	for fname, code := range p.Config.Injects {
		if _, ok := injects[fname]; !ok {
			injects[fname] = []string{}
		}
		injects[fname] = append(injects[fname], code...)
	}

	s := struct {
		LoaderContent     string
		ProfileDefContent string
		EmbedScripts      []string
		Injects           map[string][]string
		RequireInjectable bool
		NoConfirm         bool
	}{
		LoaderContent:     string(loaderContent),
		ProfileDefContent: string(profileDef),
		EmbedScripts:      embedScripts,
		Injects:           injects,
		RequireInjectable: p.Config.RequireInjectable,
		NoConfirm:         p.NoConfirm,
	}

	profileDefContent, err := profileDefTemplate()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	funcs := template.FuncMap{
		"inject_script": func(file string) string {
			bytes, err := os.ReadFile(file)
			if err != nil {
				return ""
			}
			stripped, err := stripShebangBytes(bytes)
			if err != nil {
				return ""
			}
			return string(stripped)
		},
	}

	tmpl, err := template.New("").Funcs(funcs).Parse(string(profileDefContent))
	if err != nil {
		return nil, errors.Wrap(err)
	}

	buf, err := tputils.Apply(tmpl, s)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	return buf.Bytes(), nil
}

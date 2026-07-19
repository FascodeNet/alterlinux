package profilegen

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/internal/profile"
	"mvdan.cc/sh/v3/syntax"
)

func profileDefPath(loaded *profile.Profile) string {
	return filepath.Join(loaded.Dir, "profiledef.sh")
}

func stripShebangBytes(data []byte) ([]byte, error) {
	parsed, err := syntax.NewParser().Parse(bytes.NewReader(data), "")
	if err != nil {
		return data, errors.Wrap(err)
	}

	var source bytes.Buffer
	if err := syntax.NewPrinter().Print(&source, parsed); err != nil {
		return data, errors.Wrap(err)
	}
	withoutShebang := source.String()
	if strings.HasPrefix(withoutShebang, "#!") {
		if index := strings.IndexByte(withoutShebang, '\n'); index >= 0 {
			withoutShebang = withoutShebang[index+1:]
		} else {
			withoutShebang = ""
		}
	}

	parsed, err = syntax.NewParser().Parse(strings.NewReader(withoutShebang), "")
	if err != nil {
		return data, errors.Wrap(err)
	}
	var minified bytes.Buffer
	if err := syntax.NewPrinter(syntax.Minify(true)).Print(&minified, parsed); err != nil {
		return data, errors.Wrap(err)
	}
	return bytes.TrimSpace(minified.Bytes()), nil
}

type profileDefinitionTemplateData struct {
	LoaderContent     string
	ProfileDefContent string
	EmbedScripts      []string
	Injects           map[string][]string
	RequireInjectable bool
	Generation        Options
}

func renderProfileDefinition(loaded *profile.Profile, options Options) ([]byte, error) {
	loaderContent, err := readAsset("loader.sh")
	if err != nil {
		return nil, errors.Newf("failed to read embedded loader: %w", err)
	}
	loaderContent, err = stripShebangBytes(loaderContent)
	if err != nil {
		return nil, errors.Newf("failed to parse embedded loader: %w", err)
	}

	profileDef, err := os.ReadFile(profileDefPath(loaded))
	if err != nil {
		return nil, errors.Newf("failed to read profiledef.sh: %w", err)
	}

	var embedScripts []string
	injects := make(map[string][]string)
	for _, module := range loaded.Modules() {
		for _, script := range module.Definition.LoadScripts {
			embedScripts = append(embedScripts, filepath.Join(module.Dir, script))
		}
		for name, code := range module.Definition.Injects {
			injects[name] = append(injects[name], code...)
		}
	}
	for name, code := range loaded.Definition.Injects {
		injects[name] = append(injects[name], code...)
	}

	templateContent, err := readAsset("profiledef.sh.in")
	if err != nil {
		return nil, errors.Newf("failed to read embedded profile template: %w", err)
	}
	tmpl, err := template.New("profiledef.sh").Funcs(template.FuncMap{
		"inject_script": func(filename string) (string, error) {
			content, err := os.ReadFile(filename)
			if err != nil {
				return "", errors.Newf("failed to read module load script %s: %w", filename, err)
			}
			stripped, err := stripShebangBytes(content)
			if err != nil {
				return "", errors.Newf("failed to parse module load script %s: %w", filename, err)
			}
			return string(stripped), nil
		},
	}).Parse(string(templateContent))
	if err != nil {
		return nil, errors.Newf("failed to parse embedded profile template: %w", err)
	}

	data := profileDefinitionTemplateData{
		LoaderContent:     string(loaderContent),
		ProfileDefContent: string(profileDef),
		EmbedScripts:      embedScripts,
		Injects:           injects,
		RequireInjectable: loaded.Definition.RequireInjectable,
		Generation:        options,
	}
	var output bytes.Buffer
	if err := tmpl.Execute(&output, data); err != nil {
		return nil, errors.Newf("failed to render profiledef.sh: %w", err)
	}
	return output.Bytes(), nil
}

func generateProfileDefinition(loaded *profile.Profile, outDir string, options Options) error {
	profileDef, err := renderProfileDefinition(loaded, options)
	if err != nil {
		return errors.Wrap(err)
	}
	if err := os.WriteFile(filepath.Join(outDir, "profiledef.sh"), profileDef, 0o644); err != nil {
		return errors.Newf("failed to write profiledef.sh: %w", err)
	}

	config, err := json.Marshal(loaded.Definition)
	if err != nil {
		return errors.Newf("failed to encode profiledef.json: %w", err)
	}
	if err := os.WriteFile(filepath.Join(outDir, "profiledef.json"), config, 0o644); err != nil {
		return errors.Newf("failed to write profiledef.json: %w", err)
	}
	return nil
}

func copyInjecter(outDir string) error {
	content, err := readAsset("injecter.sh")
	if err != nil {
		return errors.Newf("failed to read embedded injecter: %w", err)
	}
	if err := os.WriteFile(filepath.Join(outDir, "injecter.sh"), content, 0o644); err != nil {
		return errors.Newf("failed to write injecter.sh: %w", err)
	}
	return nil
}

package archiso

import (
	"bytes"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/pkg/shkv"
	"github.com/FascodeNet/alterlinux/src/pkg/shutils"
	"github.com/Hayao0819/nahi/tputils"
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

func UnmarshalProfileDef(data []byte) (ProfileDef, error) {
	var profileDef ProfileDef
	if err := shkv.Unmarshal(string(data), &profileDef); err != nil {
		return ProfileDef{}, errors.Wrap(err)
	}
	return profileDef, nil
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

	profileDef, err := shkv.Marshal(p.Archiso)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	s := struct {
		LoaderContent     string
		ProfileDefContent string
	}{
		LoaderContent:     string(loaderContent),
		ProfileDefContent: string(profileDef),
	}

	profileDefContent, err := profileDefTemplate()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	buf, err := tputils.ApplyToText(string(profileDefContent), s)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	return buf.Bytes(), nil
}

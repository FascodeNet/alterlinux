package archiso

import (
	"bytes"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/FascodeNet/alterlinux/src/pkg/shutils"
	"github.com/Hayao0819/nahi/tputils"
	"mvdan.cc/sh/v3/syntax"
)

type ArchisoProfile struct {
	ISOName                  string            `shkv:"iso_name"`
	ISOLavel                 string            `shkv:"iso_label"`
	ISOPublisher             string            `shkv:"iso_publisher"`
	ISOApplication           string            `shkv:"iso_application"`
	ISOVersion               string            `shkv:"iso_version"`
	InstallDir               string            `shkv:"install_dir"`
	BuildModes               []string          `shkv:"build_modes"`
	Arch                     string            `shkv:"arch"`
	PacmanConf               string            `shkv:"pacman_conf"`
	AirootfsImageType        string            `shkv:"airootfs_image_type"`
	AirootfsImageToolOptions []string          `shkv:"airootfs_image_tool_options"`
	FilePermissions          map[string]string `shkv:"file_permissions"`
}

type ProfileDef struct {
	Archiso         ArchisoProfile
	ConfigPath      string
	BootloadersPath string
}

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

func (p *ProfileDef) ProfileDefSh() ([]byte, error) {
	loaderContent, err := loader()
	if err != nil {
		return nil, errors.Wrap(err)
	}

    loaderContent, err = stripShebangBytes(loaderContent)
    if err != nil {
        return nil, errors.Wrap(err)
    }

	s := struct {
		LoaderContent     string
		ProfileDefContent string
	}{
		LoaderContent:     string(loaderContent),
		ProfileDefContent: "",
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

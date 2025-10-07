package archiso

import (
	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/Hayao0819/nahi/tputils"
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

func (p *ProfileDef) ProfileDefSh() ([]byte, error) {
	loaderContent, err := loader()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	profileDefContent, err := profileDefTemplate()
	if err != nil {
		return nil, errors.Wrap(err)
	}

	s := struct {
		LoaderContent     []byte
		ProfileDefContent []byte
	}{
		LoaderContent:     loaderContent,
		ProfileDefContent: profileDefContent,
	}

	buf, err := tputils.ApplyToText(string(profileDefContent), s)
	if err != nil {
		return nil, errors.Wrap(err)
	}

	return buf.Bytes(), nil
}

package archiso

type ProfileDef struct {
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

type Profile struct {
	Archiso         ProfileDef
	ConfigPath      string
	BootloadersPath string
}

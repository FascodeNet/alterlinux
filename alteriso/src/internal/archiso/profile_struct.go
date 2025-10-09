package archiso

type ProfileDef struct {
	ISOName                     string            `shkv:"iso_name"`
	ISOLavel                    string            `shkv:"iso_label"`
	ISOPublisher                string            `shkv:"iso_publisher"`
	ISOApplication              string            `shkv:"iso_application"`
	ISOVersion                  string            `shkv:"iso_version"`
	InstallDir                  string            `shkv:"install_dir"`
	BuildModes                  []string          `shkv:"buildmodes"`
	Bootmodes                   []string          `shkv:"bootmodes"`
	Arch                        string            `shkv:"arch"`
	PacmanConf                  string            `shkv:"pacman_conf"`
	AirootfsImageType           string            `shkv:"airootfs_image_type"`
	AirootfsImageToolOptions    []string          `shkv:"airootfs_image_tool_options"`
	BootstrapTarballCompression []string          `shkv:"bootstrap_tarball_compression"`
	FilePermissions             map[string]string `shkv:"file_permissions"`
	modules                     []string          `shkv:"alteriso_modules"`
}

type Profile struct {
	Archiso         ProfileDef
	ConfigPath      string
	BootloadersPath string
}

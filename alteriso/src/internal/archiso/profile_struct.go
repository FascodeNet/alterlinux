package archiso

type Profile struct {
	Config          ProfileDef
	modules         []Module
	Path            string
	BootloadersPath string
	ModulesPath     string
}

type ProfileDef struct {
	Arch         string              `json:"arch"`
	Modules      []string            `json:"modules"`
	OSName       string              `json:"os_name"`
	KernelName   string              `json:"kernel_name"`
	UserName     string              `json:"username"`
	Injects      map[string][]string `json:"injects"`
	COWSpaceSize string              `json:"cow_spacesize"`
}

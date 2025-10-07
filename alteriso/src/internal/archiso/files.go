package archiso

import (
	"embed"
)

//go:embed archiso/*
var archisoScripts embed.FS

func injecter() ([]byte, error) {
	return archisoScripts.ReadFile("archiso/injecter.sh")
}

func profileDefTemplate() ([]byte, error) {
	return archisoScripts.ReadFile("archiso/profiledef.sh.in")
}

func loader() ([]byte, error) {
	return archisoScripts.ReadFile("archiso/loader.sh")
}

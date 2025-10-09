package archiso

import (
	"embed"
)

//go:embed injects/*
var archisoScripts embed.FS

func injecter() ([]byte, error) {
	return archisoScripts.ReadFile("injects/injecter.sh")
}

func profileDefTemplate() ([]byte, error) {
	return archisoScripts.ReadFile("injects/profiledef.sh.in")
}

func loader() ([]byte, error) {
	return archisoScripts.ReadFile("injects/loader.sh")
}

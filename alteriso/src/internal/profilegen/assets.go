package profilegen

import (
	"embed"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

//go:embed assets/*
var assets embed.FS

func readAsset(name string) ([]byte, error) {
	data, err := assets.ReadFile("assets/" + name)
	if err != nil {
		return nil, errors.Wrap(err)
	}
	return data, nil
}

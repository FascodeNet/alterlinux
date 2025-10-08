package cmd

import "github.com/FascodeNet/alterlinux/src/internal/cmd/profile"

func init() {
	rootReg.Add(profile.Cmd())
}

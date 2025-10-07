package main

import (
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/cmd"
	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

func main() {
	if err := cmd.Execute(); err != nil {
		errors.Print(err)
		os.Exit(1)
	}
}

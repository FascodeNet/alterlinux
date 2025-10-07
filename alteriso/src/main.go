package main

import (
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}

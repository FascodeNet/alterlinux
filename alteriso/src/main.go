package main

import (
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/cmd"
	_ "github.com/FascodeNet/alterlinux/src/internal/logger"
)

func main() {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}

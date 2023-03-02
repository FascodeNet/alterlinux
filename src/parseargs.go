package main

import (
	flag "github.com/spf13/pflag"
	"github.com/FascodeNet/alterlinux/src/conf"
)


func ParseArgs(args []string) (*conf.Config, error) {
	config := &BuildConfig
	defConf := &DefaultConfig

	flag.StringVarP(&config.Build.SfsComp, "comp-type", "c", defConf.Build.SfsComp, "")
	flag.StringVarP(&config.Build.Kernel, "kernel", "k", defConf.Build.Kernel, "Set kernel")

	return config, nil
}

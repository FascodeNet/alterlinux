package src

import flag "github.com/spf13/pflag"

func ParseArgs(args []string)(*Config, error){
	conf := &BuildConfig
	defConf := &DefaultConfig

	flag.StringVarP(&conf.SfsComp, "comp-type", "c", defConf.SfsComp, "")
	flag.StringVarP(&conf.Kernel, "kernel", "k", defConf.Kernel, "Set kernel")

	return conf, nil
}

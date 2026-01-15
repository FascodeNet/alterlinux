package shutils

import (
	"encoding/json"
	"fmt"
	"os"

	"mvdan.cc/sh/v3/syntax"
)

func PrintJSON(node syntax.Node) {
	jsonData, err := json.Marshal(node)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(jsonData))
}

func PrintCode(node syntax.Node) {

	if node == nil {
		return
	}
	printer := syntax.NewPrinter(syntax.Minify(true))
	err := printer.Print(os.Stdout, node)
	if err != nil {
		panic(err)
	}
}

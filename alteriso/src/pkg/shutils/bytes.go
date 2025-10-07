package shutils

import (
	"bytes"

	"mvdan.cc/sh/v3/syntax"
)

func ToBytes(node syntax.Node, opts ...syntax.PrinterOption) ([]byte, error) {
	printer := syntax.NewPrinter(syntax.Minify(true))
	buf := bytes.Buffer{}
	err := printer.Print(&buf, node)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

package shutils

import (
	"bytes"
	"io"
	"os"

	"mvdan.cc/sh/v3/syntax"
)

func Parse(r io.Reader, name string, opts ...syntax.ParserOption) (*syntax.File, error) {
	parser := syntax.NewParser(opts...)
	parsed, err := parser.Parse(r, name)
	if err != nil {
		return nil, err
	}

	return parsed, nil
}

func ParseFile(path string, opts ...syntax.ParserOption) (*syntax.File, error) {
	f, err := os.OpenFile(path, os.O_RDONLY, 0)
	if err != nil {
		return nil, err
	}

	return Parse(f, path, opts...)
}

func ParseBytes(data []byte, name string, opts ...syntax.ParserOption) (*syntax.File, error) {
	buf := bytes.NewBuffer(data)
	return Parse(buf, name, opts...)
}

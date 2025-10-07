package errors

import "github.com/ztrue/tracerr"

func New(msg string) error {
	return tracerr.New(msg)
}

func Wrap(err error) error {
	return tracerr.Wrap(err)
}

func Print(err error) {
	tracerr.PrintSourceColor(err)
}

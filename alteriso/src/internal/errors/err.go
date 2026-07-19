// Package errors is the sole adapter between alteriso and its error
// implementation. Application packages must create and wrap errors through
// this package so the underlying library can be replaced in one place.
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

func Newf(format string, args ...interface{}) error {
	return tracerr.Errorf(format, args...)
}

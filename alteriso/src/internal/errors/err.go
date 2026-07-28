// Package errors is the sole adapter between alteriso and its error
// implementation. Application packages must create and wrap errors through
// this package so the underlying library can be replaced in one place.
package errors

import (
	stderrors "errors"
	"fmt"

	"github.com/ztrue/tracerr"
)

// ErrReported marks a failure the command already explained to the user. The
// entry point turns it into a non-zero exit without adding a message or a
// stack trace, so a negative verdict does not read as a crash.
var ErrReported = stderrors.New("reported")

// Reported wraps ErrReported with context for callers that inspect the error.
func Reported(format string, args ...any) error {
	return fmt.Errorf("%s: %w", fmt.Sprintf(format, args...), ErrReported)
}

func IsReported(err error) bool {
	return stderrors.Is(err, ErrReported)
}

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

package errors_test

import (
	stderrors "errors"
	"testing"

	altererrors "github.com/FascodeNet/alterlinux/src/internal/errors"
)

func TestWrapPreservesCause(t *testing.T) {
	cause := stderrors.New("cause")

	if err := altererrors.Wrap(cause); !stderrors.Is(err, cause) {
		t.Fatalf("errors.Is(Wrap(cause), cause) = false")
	}
}

func TestNewfPreservesWrappedCause(t *testing.T) {
	cause := stderrors.New("cause")

	err := altererrors.Newf("context: %w", cause)
	if !stderrors.Is(err, cause) {
		t.Fatalf("errors.Is(Newf(...), cause) = false")
	}
}

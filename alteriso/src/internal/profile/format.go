package profile

import "github.com/FascodeNet/alterlinux/src/internal/errors"

// ErrFormatNotImplemented is intentionally returned by the CLI until a profile
// formatting contract has been designed and implemented.
var ErrFormatNotImplemented = errors.New("profile formatting is not implemented")

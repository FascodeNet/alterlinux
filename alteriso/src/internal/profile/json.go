package profile

import (
	"bytes"
	"encoding/json"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

func decodeJSONFile(filename, label string, destination any) error {
	content, err := os.ReadFile(filename)
	if err != nil {
		return errors.Newf("failed to read %s: %w", label, err)
	}
	decoder := json.NewDecoder(bytes.NewReader(content))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return errors.Newf("failed to parse %s: %w", label, err)
	}
	return nil
}

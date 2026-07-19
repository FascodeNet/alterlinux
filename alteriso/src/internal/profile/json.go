package profile

import (
	"encoding/json"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

func decodeJSONFile(filename, label string, destination any) error {
	content, err := os.ReadFile(filename)
	if err != nil {
		return errors.Newf("failed to read %s: %w", label, err)
	}
	if err := json.Unmarshal(content, destination); err != nil {
		return errors.Newf("failed to parse %s: %w", label, err)
	}
	return nil
}

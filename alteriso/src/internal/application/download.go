package application

import (
	"io"
	"net/http"
	"os"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

// downloadFile stores a successful HTTP response in destination and applies mode.
func downloadFile(client *http.Client, url, destination string, mode os.FileMode) error {
	if client == nil {
		client = http.DefaultClient
	}
	response, err := client.Get(url)
	if err != nil {
		return errors.Newf("failed to download %s: %w", url, err)
	}
	defer func() {
		_ = response.Body.Close()
	}()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		return errors.Newf(
			"failed to download %s: unexpected HTTP status %d %s",
			url,
			response.StatusCode,
			http.StatusText(response.StatusCode),
		)
	}

	file, err := os.OpenFile(destination, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, mode)
	if err != nil {
		return errors.Newf("failed to open download destination %s: %w", destination, err)
	}
	if _, err := io.Copy(file, response.Body); err != nil {
		_ = file.Close()
		return errors.Newf("failed to write download destination %s: %w", destination, err)
	}
	if err := file.Close(); err != nil {
		return errors.Newf("failed to close download destination %s: %w", destination, err)
	}
	if err := os.Chmod(destination, mode); err != nil {
		return errors.Newf("failed to set download permissions on %s: %w", destination, err)
	}
	return nil
}

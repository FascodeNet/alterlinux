package application

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return f(request)
}

func responseClient(statusCode int, body string) *http.Client {
	return &http.Client{Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
		return &http.Response{
			StatusCode: statusCode,
			Status:     http.StatusText(statusCode),
			Body:       io.NopCloser(strings.NewReader(body)),
			Header:     make(http.Header),
			Request:    request,
		}, nil
	})}
}

func TestDownload(t *testing.T) {
	destination := filepath.Join(t.TempDir(), "download")
	if err := downloadFile(responseClient(http.StatusOK, "content"), "https://example.invalid/file", destination, 0o755); err != nil {
		t.Fatalf("downloadFile() error = %v", err)
	}
	content, err := os.ReadFile(destination)
	if err != nil {
		t.Fatalf("failed to read download: %v", err)
	}
	if string(content) != "content" {
		t.Errorf("download content = %q, want content", content)
	}
	info, err := os.Stat(destination)
	if err != nil {
		t.Fatalf("failed to stat download: %v", err)
	}
	if got := info.Mode().Perm(); got != 0o755 {
		t.Errorf("download mode = %o, want 755", got)
	}
}

func TestDownloadRejectsErrorStatus(t *testing.T) {
	err := downloadFile(
		responseClient(http.StatusNotFound, "missing"),
		"https://example.invalid/missing",
		filepath.Join(t.TempDir(), "download"),
		0o644,
	)
	if err == nil || !strings.Contains(err.Error(), "404") {
		t.Fatalf("downloadFile() error = %v, want HTTP 404", err)
	}
}

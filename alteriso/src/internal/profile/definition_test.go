package profile

import (
	"strings"
	"testing"
)

func TestDefinitionValidateModules(t *testing.T) {
	tests := []struct {
		name      string
		modules   []string
		wantError string
	}{
		{
			name:      "missing modules",
			wantError: `must declare "modules" as an array`,
		},
		{
			name:    "empty module list",
			modules: []string{},
		},
		{
			name:      "empty module name",
			modules:   []string{""},
			wantError: "contains an empty module name",
		},
		{
			name:      "module name with whitespace",
			modules:   []string{" base"},
			wantError: "contains leading or trailing whitespace",
		},
		{
			name:      "duplicate module",
			modules:   []string{"base", "base"},
			wantError: `declares module "base" more than once`,
		},
		{
			name:      "module path",
			modules:   []string{"../base"},
			wantError: "must be a directory name, not a path",
		},
		{
			name:    "valid modules",
			modules: []string{"base", "live-user"},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := (Definition{Arch: "x86_64", Modules: test.modules}).Validate()
			if test.wantError == "" {
				if err != nil {
					t.Fatalf("Definition.Validate() error = %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), test.wantError) {
				t.Fatalf("Definition.Validate() error = %v, want %q", err, test.wantError)
			}
		})
	}
}

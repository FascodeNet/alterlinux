package injectable

import "testing"

func TestCommandReturnsErrorWhenArchisoIsNotInjectable(t *testing.T) {
	cmd := newCommand(func() (bool, error) {
		return false, nil
	})
	cmd.SilenceErrors = true
	cmd.SilenceUsage = true

	err := cmd.Execute()
	if err == nil {
		t.Fatal("Execute() error = nil, want non-nil")
	}
	if err.Error() != "archiso is not injectable" {
		t.Fatalf("Execute() error = %q, want %q", err, "archiso is not injectable")
	}
}

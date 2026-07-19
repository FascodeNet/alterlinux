package archiso

import (
	"errors"
	"testing"
)

func TestCheckInjectabilityRunsGeneratedProfile(t *testing.T) {
	var executed command
	injectable, err := checkInjectability(func(spec command) error {
		executed = spec
		return nil
	})
	if err != nil {
		t.Fatalf("checkInjectability() error = %v", err)
	}
	if !injectable {
		t.Fatal("checkInjectability() = false, want true")
	}
	if executed.path != "fakeroot" {
		t.Errorf("command path = %q, want fakeroot", executed.path)
	}
	if len(executed.args) != 3 ||
		executed.args[0] != "mkarchiso" ||
		executed.args[1] != "-v" ||
		executed.args[2] == "" {
		t.Errorf("command args = %#v", executed.args)
	}
}

func TestCheckInjectabilityTreatsCommandFailureAsIncompatible(t *testing.T) {
	injectable, err := checkInjectability(func(spec command) error {
		return errors.New("incompatible")
	})
	if err != nil {
		t.Fatalf("checkInjectability() error = %v", err)
	}
	if injectable {
		t.Fatal("checkInjectability() = true, want false")
	}
}

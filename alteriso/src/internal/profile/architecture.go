package profile

import (
	"encoding/json"
	"strings"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
)

const AnyArchitecture = "any"

// ModuleArchitectures represents the module manifest union:
//
//	"any" | string[]
//
// The fields are deliberately private so invalid values can only enter through
// JSON decoding.
type ModuleArchitectures struct {
	all    bool
	values []string
}

func (a *ModuleArchitectures) UnmarshalJSON(data []byte) error {
	var value any
	if err := json.Unmarshal(data, &value); err != nil {
		return errors.Newf(`"arch" must be "any" or an array of strings: %w`, err)
	}

	*a = ModuleArchitectures{}
	switch architectures := value.(type) {
	case string:
		if architectures != AnyArchitecture {
			return errors.Newf(
				`"arch" only accepts %q as a string; use an array for concrete architectures`,
				AnyArchitecture,
			)
		}
		a.all = true
	case []any:
		a.values = make([]string, len(architectures))
		for index, item := range architectures {
			architecture, ok := item.(string)
			if !ok {
				return errors.Newf(`"arch" array item at index %d must be a string`, index)
			}
			a.values[index] = architecture
		}
	default:
		return errors.New(`"arch" must be "any" or an array of strings`)
	}

	return nil
}

func (a ModuleArchitectures) MarshalJSON() ([]byte, error) {
	var (
		data []byte
		err  error
	)
	if a.all {
		data, err = json.Marshal(AnyArchitecture)
	} else {
		data, err = json.Marshal(a.values)
	}
	if err != nil {
		return nil, errors.Wrap(err)
	}
	return data, nil
}

func (a ModuleArchitectures) IsAny() bool {
	return a.all
}

func (a ModuleArchitectures) Values() []string {
	return append([]string(nil), a.values...)
}

func (a ModuleArchitectures) Supports(architecture string) bool {
	if architecture == "" || architecture == AnyArchitecture {
		return false
	}
	if a.all {
		return true
	}
	for _, supported := range a.values {
		if supported == architecture {
			return true
		}
	}
	return false
}

func (a ModuleArchitectures) String() string {
	if a.all {
		return AnyArchitecture
	}
	return strings.Join(a.values, ", ")
}

func (a ModuleArchitectures) validate() error {
	if a.all {
		return nil
	}
	if len(a.values) == 0 {
		return errors.New(`module manifest must declare "arch" as "any" or a non-empty array`)
	}

	seen := make(map[string]struct{}, len(a.values))
	for index, architecture := range a.values {
		if architecture == "" {
			return errors.Newf(`module manifest contains an empty architecture at "arch" index %d`, index)
		}
		if strings.TrimSpace(architecture) != architecture {
			return errors.Newf("module manifest architecture %q contains leading or trailing whitespace", architecture)
		}
		if architecture == AnyArchitecture {
			return errors.New(`module manifest must declare the wildcard as "arch": "any", not inside an array`)
		}
		if _, ok := seen[architecture]; ok {
			return errors.Newf("module manifest declares architecture %q more than once", architecture)
		}
		seen[architecture] = struct{}{}
	}

	return nil
}

func validateConcreteArchitecture(architecture, owner string) error {
	if architecture == "" {
		return errors.Newf("%s architecture must not be empty", owner)
	}
	if architecture == AnyArchitecture {
		return errors.Newf(`%s architecture must be concrete and cannot be "any"`, owner)
	}
	if strings.TrimSpace(architecture) != architecture {
		return errors.Newf("%s architecture %q contains leading or trailing whitespace", owner, architecture)
	}
	return nil
}

// LLM Generated: Created by Claude
package profile

import (
	"slices"

	"github.com/FascodeNet/alterlinux/src/internal/errors"
	"github.com/samber/lo"
)

// OptionType names the value shapes a module option accepts. Anything richer
// belongs in the module script, not in the manifest.
type OptionType string

const (
	OptionTypeString     OptionType = "string"
	OptionTypeBool       OptionType = "bool"
	OptionTypeStringList OptionType = "string[]"
)

// OptionSpec declares one option a module accepts from the profile.
type OptionSpec struct {
	Type        OptionType `json:"type"`
	Default     any        `json:"default"`
	Required    bool       `json:"required"`
	Description string     `json:"description"`
}

func (s OptionSpec) validate(module, name string) error {
	switch s.Type {
	case OptionTypeString, OptionTypeBool, OptionTypeStringList:
	case "":
		return errors.Newf("module %q option %q must declare a type", module, name)
	default:
		return errors.Newf(
			"module %q option %q declares unsupported type %q (supported types: %s, %s, %s)",
			module, name, s.Type, OptionTypeString, OptionTypeBool, OptionTypeStringList,
		)
	}
	if s.Required && s.Default != nil {
		return errors.Newf("module %q option %q cannot be required and have a default", module, name)
	}
	if s.Default == nil {
		return nil
	}
	if _, err := coerceOptionValue(s.Type, s.Default); err != nil {
		return errors.Newf("module %q option %q has an invalid default: %w", module, name, err)
	}
	return nil
}

// coerceOptionValue narrows a decoded JSON value to the declared type. JSON
// arrays decode to []any, so string lists are rebuilt through lo.FromAnySlice.
func coerceOptionValue(optionType OptionType, value any) (any, error) {
	switch optionType {
	case OptionTypeString:
		text, ok := value.(string)
		if !ok {
			return nil, errors.Newf("expected a string, got %T", value)
		}
		return text, nil
	case OptionTypeBool:
		enabled, ok := value.(bool)
		if !ok {
			return nil, errors.Newf("expected a bool, got %T", value)
		}
		return enabled, nil
	case OptionTypeStringList:
		if texts, ok := value.([]string); ok {
			return slices.Clone(texts), nil
		}
		items, ok := value.([]any)
		if !ok {
			return nil, errors.Newf("expected an array of strings, got %T", value)
		}
		texts, ok := lo.FromAnySlice[string](items)
		if !ok {
			return nil, errors.New("expected an array of strings")
		}
		return texts, nil
	}
	return nil, errors.Newf("unsupported option type %q", optionType)
}

func sortedKeys[V any](values map[string]V) []string {
	return slices.Sorted(slices.Values(lo.Keys(values)))
}

// undeclared returns the first name that is not a key of declarations.
func undeclared[V any](names []string, declarations map[string]V) (string, bool) {
	return lo.Find(names, func(name string) bool {
		return !lo.HasKey(declarations, name)
	})
}

// resolveModuleOptions merges the profile values over the module defaults and
// rejects anything the module did not declare.
func resolveModuleOptions(definition Definition, modules []Module) (map[string]map[string]any, error) {
	byName := lo.SliceToMap(modules, func(module Module) (string, Module) { return module.Name, module })
	if name, found := undeclared(sortedKeys(definition.ModuleOptions), byName); found {
		return nil, errors.Newf(`"module_options" configures module %q which is not in "modules"`, name)
	}

	resolved := make(map[string]map[string]any)
	for _, module := range modules {
		values, err := module.resolveOptions(definition.ModuleOptions[module.Name])
		if err != nil {
			return nil, errors.Wrap(err)
		}
		if len(values) > 0 {
			resolved[module.Name] = values
		}
	}
	return resolved, nil
}

func (m Module) resolveOptions(values map[string]any) (map[string]any, error) {
	specs := m.Definition.Options
	if name, found := undeclared(sortedKeys(values), specs); found {
		return nil, errors.Newf("module %q does not declare option %q", m.Name, name)
	}

	resolved := make(map[string]any, len(specs))
	for _, name := range sortedKeys(specs) {
		spec := specs[name]
		value, ok := values[name]
		if !ok {
			if spec.Required {
				return nil, errors.Newf("module %q requires option %q", m.Name, name)
			}
			if spec.Default == nil {
				continue
			}
			value = spec.Default
		}
		coerced, err := coerceOptionValue(spec.Type, value)
		if err != nil {
			return nil, errors.Newf("module %q option %q: %w", m.Name, name, err)
		}
		resolved[name] = coerced
	}
	return resolved, nil
}

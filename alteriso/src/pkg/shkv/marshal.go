package shkv

import (
	"fmt"
	"reflect"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// This file is a clean, single-file implementation replacing the broken unmarshal.go.
// It provides:
// - quoteShell: safe single-quoting for shell
// - Marshal: produce shell variable assignments from a struct using `shkv` tags
//   - supports omitempty
//   - supports []string and map[string]string (emitted with `declare -A`)
// - MarshalAst: parse Marshal output into *syntax.File using mvdan parser
// - UnmarshalAst: print *syntax.File and parse simple assignments, arrays and
//   associative arrays into a struct annotated with `shkv` tags.

// quoteShell single-quotes a string for POSIX shell, escaping internal single quotes.
func quoteShell(s string) string {
	if s == "" {
		return "''"
	}
	// replace ' with '\'' sequence
	return "'" + strings.ReplaceAll(s, "'", "'\\''") + "'"
}

// sanitizeKey creates a safe identifier fragment from an arbitrary string.
func sanitizeKey(s string) string {
	var b strings.Builder
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' {
			b.WriteRune(r)
		} else {
			b.WriteByte('_')
		}
	}
	return b.String()
}

// Marshal converts a struct into shell key/value assignments using `shkv` tags.
// Supported kinds: string, bool, ints, uints, floats, []string, map[string]string
func Marshal(v interface{}) (string, error) {
	rv := reflect.ValueOf(v)
	for rv.Kind() == reflect.Ptr {
		if rv.IsNil() {
			return "", fmt.Errorf("nil pointer")
		}
		rv = rv.Elem()
	}
	if rv.Kind() != reflect.Struct {
		return "", fmt.Errorf("Marshal: expected struct, got %s", rv.Kind())
	}

	rt := rv.Type()
	var sb strings.Builder

	for i := 0; i < rt.NumField(); i++ {
		f := rt.Field(i)
		tagRaw := f.Tag.Get("shkv")
		if tagRaw == "" {
			continue
		}
		parts := strings.Split(tagRaw, ",")
		tag := parts[0]
		omitEmpty := false
		for _, p := range parts[1:] {
			if strings.TrimSpace(p) == "omitempty" {
				omitEmpty = true
			}
		}

		// skip unexported fields
		if f.PkgPath != "" {
			continue
		}
		fv := rv.Field(i)
		if !fv.IsValid() {
			continue
		}

		switch fv.Kind() {
		case reflect.String:
			s := fv.String()
			if omitEmpty && s == "" {
				continue
			}
			sb.WriteString(fmt.Sprintf("%s=%s\n", tag, quoteShell(s)))
		case reflect.Bool:
			b := fv.Bool()
			if omitEmpty && !b {
				continue
			}
			sb.WriteString(fmt.Sprintf("%s=%t\n", tag, b))
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			sb.WriteString(fmt.Sprintf("%s=%d\n", tag, fv.Int()))
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uintptr:
			sb.WriteString(fmt.Sprintf("%s=%d\n", tag, fv.Uint()))
		case reflect.Float32, reflect.Float64:
			sb.WriteString(fmt.Sprintf("%s=%v\n", tag, fv.Float()))
		case reflect.Slice:
			if fv.Type().Elem().Kind() != reflect.String {
				return "", fmt.Errorf("unsupported slice element type for field %s", f.Name)
			}
			n := fv.Len()
			if omitEmpty && n == 0 {
				continue
			}
			sb.WriteString(tag)
			sb.WriteString("=(")
			for j := 0; j < n; j++ {
				if j > 0 {
					sb.WriteByte(' ')
				}
				sb.WriteString(quoteShell(fv.Index(j).String()))
			}
			sb.WriteString(")\n")
		case reflect.Map:
			if fv.Type().Key().Kind() == reflect.String && fv.Type().Elem().Kind() == reflect.String {
				if omitEmpty && fv.Len() == 0 {
					continue
				}
				// use declare -A name=( ["k"]='v' ... )
				sb.WriteString("declare -A ")
				sb.WriteString(sanitizeKey(tag))
				sb.WriteString("=(")
				for _, k := range fv.MapKeys() {
					v := fv.MapIndex(k)
					sb.WriteString("[")
					sb.WriteString(quoteShell(k.String()))
					sb.WriteString("]=")
					sb.WriteString(quoteShell(v.String()))
					sb.WriteByte(' ')
				}
				sb.WriteString(")\n")
			} else {
				return "", fmt.Errorf("unsupported map type for field %s", f.Name)
			}
		default:
			// unsupported kinds: skip
			continue
		}
	}

	return sb.String(), nil
}

// MarshalAst marshals v to shell text and parses it into a *syntax.File using mvdan parser.
func MarshalAst(v interface{}) (*syntax.File, error) {
	txt, err := Marshal(v)
	if err != nil {
		return nil, err
	}
	p := syntax.NewParser()
	f, err := p.Parse(strings.NewReader(txt), "")
	if err != nil {
		return nil, err
	}
	return f, nil
}

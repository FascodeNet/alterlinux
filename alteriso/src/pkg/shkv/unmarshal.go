package shkv

import (
	"fmt"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"unicode"

	"github.com/FascodeNet/alterlinux/src/pkg/shutils"
	"mvdan.cc/sh/v3/syntax"
)

func Unmarshal(d string, out interface{}) error {
	ast, err := shutils.ParseBytes([]byte(d), "")
	if err != nil {
		return err
	}
	return UnmarshalAst(ast, out)
}

// UnmarshalAst prints the AST to text and extracts variables into out (pointer to struct).
// It supports simple assignments, arrays like name=(a b) and associative arrays like
// name=( ["k"]="v" ... ) or declare -A name=( ... ).
func UnmarshalAst(f *syntax.File, out interface{}) error {
	rv := reflect.ValueOf(out)
	if rv.Kind() != reflect.Ptr || rv.IsNil() {
		return fmt.Errorf("out must be non-nil pointer to struct")
	}
	rv = rv.Elem()
	if rv.Kind() != reflect.Struct {
		return fmt.Errorf("out must point to struct")
	}

	rt := rv.Type()
	tagToField := map[string]int{}
	for i := 0; i < rt.NumField(); i++ {
		tag := rt.Field(i).Tag.Get("shkv")
		if tag != "" {
			tagToField[tag] = i
		}
	}

	// Process each statement by printing it and parsing the resulting text.
	for _, stmt := range f.Stmts {
		txt := strings.TrimSpace(nodeToString(stmt))
		if txt == "" || strings.HasPrefix(txt, "#") {
			continue
		}
		if strings.HasPrefix(txt, "declare -A ") {
			parts := strings.SplitN(txt, "=", 2)
			if len(parts) != 2 {
				continue
			}
			left := strings.TrimSpace(parts[0])
			leftParts := strings.Fields(left)
			if len(leftParts) >= 3 {
				name := leftParts[2]
				if fi, ok := tagToField[name]; ok {
					fld := rv.Field(fi)
					if fld.Kind() != reflect.Map {
						continue
					}
					if fld.IsNil() {
						fld.Set(reflect.MakeMap(fld.Type()))
					}
					right := parts[1]
					assocRe := regexp.MustCompile(`\[\s*(['"])(.*?)['"]\s*\]\s*=\s*(['"])(.*?)['"]`)
					for _, m := range assocRe.FindAllStringSubmatch(right, -1) {
						k := m[2]
						v := m[4]
						fld.SetMapIndex(reflect.ValueOf(k), reflect.ValueOf(v))
					}
				}
			}
			continue
		}

		if eq := strings.Index(txt, "="); eq >= 0 {
			name := strings.TrimSpace(txt[:eq])
			rhs := strings.TrimSpace(txt[eq+1:])
			if fi, ok := tagToField[name]; ok {
				fld := rv.Field(fi)
				if strings.HasPrefix(rhs, "(") && strings.HasSuffix(rhs, ")") {
					// array or empty
					inside := strings.TrimSpace(rhs[1 : len(rhs)-1])
					if fld.Kind() == reflect.Slice {
						if inside == "" {
							fld.Set(reflect.MakeSlice(fld.Type(), 0, 0))
							continue
						}
						parts := splitShellFields(inside)
						slv := reflect.MakeSlice(fld.Type(), len(parts), len(parts))
						for i, p := range parts {
							if slv.Index(i).Kind() == reflect.String {
								slv.Index(i).SetString(p)
							} else {
								return fmt.Errorf("unsupported slice element type for field %s", rt.Field(fi).Name)
							}
						}
						fld.Set(slv)
					}
					continue
				}
				// scalar
				setScalarValue(fld, rhs, rt.Field(fi).Name)
			}
		}
	}

	return nil
}

// splitShellFields splits a parenthesis-inside shell arg list into fields (naive but sufficient for quoted words).
func splitShellFields(s string) []string {
	var out []string
	var cur strings.Builder
	inSq := false
	inDq := false
	esc := false
	for _, r := range s {
		if esc {
			cur.WriteRune(r)
			esc = false
			continue
		}
		if r == '\\' {
			esc = true
			continue
		}
		if r == '\'' && !inDq {
			inSq = !inSq
			continue
		}
		if r == '"' && !inSq {
			inDq = !inDq
			continue
		}
		if unicode.IsSpace(r) && !inSq && !inDq {
			if cur.Len() > 0 {
				out = append(out, cur.String())
				cur.Reset()
			}
			continue
		}
		cur.WriteRune(r)
	}
	if cur.Len() > 0 {
		out = append(out, cur.String())
	}
	return out
}

// nodeToString prints a syntax.Node into source-like text using syntax printer.
func nodeToString(n syntax.Node) string {
	var b strings.Builder
	_ = syntax.NewPrinter().Print(&b, n)
	return b.String()
}

// (removed wordToString; using nodeToString for stringification)

// setScalarValue sets a scalar value into fld from txt (shell-quoted or raw).
func setScalarValue(fld reflect.Value, txt, fieldName string) {
	// unquote simple single or double quotes
	if len(txt) >= 2 {
		if (txt[0] == '\'' && txt[len(txt)-1] == '\'') || (txt[0] == '"' && txt[len(txt)-1] == '"') {
			txt = txt[1 : len(txt)-1]
		}
	}
	switch fld.Kind() {
	case reflect.String:
		fld.SetString(txt)
	case reflect.Bool:
		if b, err := strconv.ParseBool(txt); err == nil {
			fld.SetBool(b)
		}
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		if iv, err := strconv.ParseInt(txt, 10, 64); err == nil {
			fld.SetInt(iv)
		}
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uintptr:
		if uv, err := strconv.ParseUint(txt, 10, 64); err == nil {
			fld.SetUint(uv)
		}
	}
}

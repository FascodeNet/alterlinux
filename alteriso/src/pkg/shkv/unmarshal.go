package shkv

import (
	"bytes"
	"fmt"
	"io"
	"reflect"
	"regexp"
	"strconv"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// UnmarshalAst prints the AST to text and extracts variables into out (pointer to struct).
// It supports simple assignments, arrays like name=(a b) and associative arrays like
// name=( ["k"]="v" ... ) or declare -A name=( ... ).
func UnmarshalAst(f *syntax.File, out interface{}) error {
	var buf bytes.Buffer
	if err := syntax.NewPrinter().Print(&buf, f); err != nil {
		return err
	}
	script := buf.String()

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

	assocRe := regexp.MustCompile(`\[\s*(['"])(.*?)['"]\s*\]\s*=\s*(['"])(.*?)['"]`)

	for _, raw := range strings.Split(script, "\n") {
		line := strings.TrimSpace(raw)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "declare -A ") {
			parts := strings.SplitN(line, "=", 2)
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
					for _, m := range assocRe.FindAllStringSubmatch(right, -1) {
						k := m[2]
						v := m[4]
						fld.SetMapIndex(reflect.ValueOf(k), reflect.ValueOf(v))
					}
				}
			}
			continue
		}

		if eq := strings.Index(line, "="); eq >= 0 {
			name := strings.TrimSpace(line[:eq])
			rhs := strings.TrimSpace(line[eq+1:])
			if fi, ok := tagToField[name]; ok {
				fld := rv.Field(fi)
				if strings.HasPrefix(rhs, "(") && strings.Contains(rhs, "[") {
					if fld.Kind() != reflect.Map {
						continue
					}
					if fld.IsNil() {
						fld.Set(reflect.MakeMap(fld.Type()))
					}
					for _, m := range assocRe.FindAllStringSubmatch(rhs, -1) {
						k := m[2]
						v := m[4]
						fld.SetMapIndex(reflect.ValueOf(k), reflect.ValueOf(v))
					}
					continue
				}
				if strings.HasPrefix(rhs, "(") {
					if fld.Kind() == reflect.Slice {
						inside := strings.TrimSpace(rhs[1 : len(rhs)-1])
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
				// scalar types
				if fld.Kind() == reflect.String {
					fld.SetString(strings.Trim(rhs, "'\""))
				} else if fld.Kind() == reflect.Bool {
					b, _ := strconv.ParseBool(rhs)
					fld.SetBool(b)
				} else if fld.Kind() >= reflect.Int && fld.Kind() <= reflect.Int64 {
					if iv, err := strconv.ParseInt(rhs, 10, 64); err == nil {
						fld.SetInt(iv)
					}
				} else if fld.Kind() >= reflect.Uint && fld.Kind() <= reflect.Uint64 {
					if uv, err := strconv.ParseUint(rhs, 10, 64); err == nil {
						fld.SetUint(uv)
					}
				}
			}

		}
	}

	return nil
}

// parseAssocPairs extracts associative array pairs from a string like:
// ( ["/etc/shadow"]="0:0:400" ["/root"]='0:0:750' )
func parseAssocPairs(s string) map[string]string {
	m := map[string]string{}
	// use regex to find ["k"]="v" occurrences
	re := regexp.MustCompile(`\[\s*(['"])([^'"]*)['"]\s*\]\s*=\s*(['"])([^'"]*)['"]`)
	for _, sub := range re.FindAllStringSubmatch(s, -1) {
		k := sub[2]
		v := sub[4]
		m[k] = v
	}
	return m
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
		if r == ' ' && !inSq && !inDq {
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

// parseWithMvdan parses reader into *syntax.File using mvdan parser (helper for MarshalAst if needed)
func parseWithMvdan(r io.Reader) (*syntax.File, error) {
	b, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}
	p := syntax.NewParser()
	f, err := p.Parse(bytes.NewReader(b), "")
	if err != nil {
		return nil, err
	}
	return f, nil
}

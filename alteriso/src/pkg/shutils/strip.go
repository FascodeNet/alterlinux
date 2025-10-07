package shutils

import (
	"bytes"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// StripShebang removes the shebang from any *syntax.File node found in the
// provided AST node. It uses reflection so it works regardless of the
// concrete type of the Shebang field (string, []byte, etc.).
// StripShebang returns a new AST (a *syntax.File) with any leading shebang
// removed. The function prints the node to source, strips a leading "#!"
// line if present, and reparses the source to produce a fresh AST.
// If parsing fails the original node is returned.
func StripShebang(node syntax.Node) syntax.Node {
	// Print the node to source
	var buf bytes.Buffer
	pr := syntax.NewPrinter()
	if err := pr.Print(&buf, node); err != nil {
		return node
	}

	src := buf.String()
	// Remove leading shebang line if present
	if strings.HasPrefix(src, "#!") {
		// drop the first line
		if idx := strings.IndexByte(src, '\n'); idx >= 0 {
			src = src[idx+1:]
		} else {
			// whole file was the shebang line -> empty
			src = ""
		}
	}

	// Reparse the source into a new AST
	parsed, err := Parse(strings.NewReader(src), "")
	if err != nil {
		// fallback: try parsing from bytes.Reader via io.Reader
		p := syntax.NewParser()
		if f, err2 := p.Parse(strings.NewReader(src), ""); err2 == nil {
			return f
		}
		return node
	}
	return parsed
}

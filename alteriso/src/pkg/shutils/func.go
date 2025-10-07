package shutils

import (
	"github.com/samber/lo"
	"mvdan.cc/sh/v3/syntax"
)

func ExtractFunctions(node syntax.Node) []*syntax.FuncDecl {
	decls := []*syntax.FuncDecl{}
	syntax.Walk(node, func(n syntax.Node) bool {
		if funcDecl, ok := n.(*syntax.FuncDecl); ok {
			decls = append(decls, funcDecl)
		}
		return true
	})
	return decls
}

func Func(node syntax.Node, name string) *syntax.FuncDecl {
	return lo.Filter(ExtractFunctions(node), func(d *syntax.FuncDecl, n int) bool {
		return d.Name.Value == name
	})[0]
}

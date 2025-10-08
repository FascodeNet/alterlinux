package utils

import (
	"fmt"
	"reflect"
	"runtime"
	"strings"
)

type Func interface{}

func FuncName(f Func) string {
	pc := reflect.ValueOf(f).Pointer()
	fn := runtime.FuncForPC(pc)

	if fn == nil {
		return ""
	}

	fullName := fn.Name()

	parts := strings.Split(fullName, ".")
	return parts[len(parts)-1]
}
func Run(f interface{}, args ...interface{}) []reflect.Value {
	v := reflect.ValueOf(f)

	funcName := FuncName(f)

	// --- エラーチェック ---
	if v.Kind() != reflect.Func {
		fmt.Printf("エラー: %s は関数ではありません。\n", funcName)
		return nil
	}
	if v.Type().NumIn() != len(args) {
		fmt.Printf("エラー: %s: 期待される引数の数(%d)と、渡された引数の数(%d)が一致しません。\n", funcName, v.Type().NumIn(), len(args))
		return nil
	}

	in := make([]reflect.Value, len(args))
	for i, arg := range args {
		in[i] = reflect.ValueOf(arg)
	}

	out := v.Call(in)

	return out
}

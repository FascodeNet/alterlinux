package utils

import (
	"encoding/json"
	"fmt"
)

func PrintJSON(v any) {
	jsonData, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(jsonData))
}

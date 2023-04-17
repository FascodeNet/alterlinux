package main

import (
	//"errors"
	"fmt"
	"os"
	"path"
	"strings"
	"text/template"
)


func handle_error(err error){
	if err ==nil{
		return
	}
	fmt.Println(err)
	os.Exit(1)
}


var TargetFile string

func main(){
	data, err := parse_args()
	handle_error(err)


	handle_error(parse_template(TargetFile, *data))
	
}

func parse_template(file string, data map[string]interface{})(error){
	funcmap := template.FuncMap{
		// csv to shell array
		"print_csv": func(csv string)(string){
			csv_array := []string{}
			for _, s := range strings.Split(csv, ","){
				csv_array=append(csv_array, fmt.Sprintf("\"%s\"", strings.TrimSpace(s)))
			}

			return strings.Join(csv_array, " ")
		},
	}


	tpl, err := template.New(path.Base(file)).Funcs(funcmap).ParseFiles(file)   //.FuncMap(funcmap).ParseFiles(file)
	if err !=nil{
		return err
	}

	err = tpl.Execute(os.Stdout, data)
	
	if err !=nil{
		return err
	}

	return nil
}

func parse_args()(*map[string]any, error){
	rtn := map[string]any{}

	// 1つめの引数はファイル
	TargetFile=os.Args[1]

	if len(os.Args) < 2{
		return nil, fmt.Errorf("no argument")
	}

	for _ , raw := range os.Args[2:]{
		s  := strings.Split(raw, "=")
		if len(s) < 2{
			return nil, fmt.Errorf("wrong syntax: %s", raw)
		}

		var_name := s[0]
		value := strings.Join(s[1:], "=")

		if len(strings.TrimSpace(value)) == 0{
			fmt.Fprintf(os.Stderr, "the value of %s is empty\n", var_name)
		}

		rtn[var_name]=value
	}

	return &rtn,nil
}

package main

import (
	"fmt"
	"os"
	"path"
	"strings"
	"text/template"
	"encoding/json"
)

type bash_vars_json struct{
	Variables map[string]string `json:"variables"`
	Array map[string][]string `json:"array"`
	Dictionary map[string]map[string]string `json:"dictionary"`
}

type bash_vars map[string]any

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

func parse_args()(*bash_vars, error){
	rtn := bash_vars_json{}

	// 1つめの引数はファイル
	TargetFile=os.Args[1]

	if len(os.Args) < 3{
		return nil, fmt.Errorf("no argument")
	}

	json.Unmarshal([]byte(os.Args[2]), &rtn)

	flat := *rtn.Flat()

	return &flat,nil
}

func (j *bash_vars_json)Flat()(*bash_vars){
	rtn := bash_vars{}
	
	for i, s := range j.Array{
		rtn[i]=s
	}

	for i, s := range j.Dictionary{
		rtn[i]=s
	}

	for i, s := range j.Variables{
		rtn[i]=s
	}

	return &rtn
}

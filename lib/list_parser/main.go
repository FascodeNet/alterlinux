package main

import (
	"bufio"
	"errors"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
)

type parser struct {
	matchColumn int
	delim        string
	varNames    []string
}

var kernel = parser{
	matchColumn: 0,
	delim:        " ",
	varNames:   []string{
		"kernel",
		"kernel_filename",
		"kernel_mkinitcpio_profile",
	},
}

var locale = parser{
	matchColumn: 0,
	delim:        " ",
	varNames:   []string{
		"locale_name",
		"locale_gen_name",
		"locale_version",
		"locale_time",
		"locale_fullname",
	},
}

func (p *parser) Parse(path string, match string) error {
	// ファイルを開く
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	//1行づつ読み込む
	scanner := bufio.NewScanner(file)
	comment := regexp.MustCompile(`^ *#.*$`)
	for scanner.Scan() {
		// コメント行は無視
		rawline := strings.Split(scanner.Text(), p.delim)
		if comment.MatchString(rawline[0]){
			continue
		}

		// 連続したスペースを削除
		line := []string{}
		for _, l := range rawline {
			if strings.TrimSpace(l) != "" {
				line = append(line, l)
			}
		}

		// 期待するカラム数と一致しない場合は無視
		if len(line) != len(p.varNames) {
			continue
		}

		// カラム名と値を出力
		if line[p.matchColumn] == match {
			for i := range line {
				fmt.Println(p.varNames[i] + "=" + line[i])
			}
		}

	}

	return nil
}


func run()error{
	p:= parser{}

	if len(os.Args) < 4 {
		return errors.New("usage: list_parser <parser> <path> <match>")
	}

	switch os.Args[1] {
	case "kernel":
		p = kernel
	case "locale":
		p = locale
	default:
		return errors.New("unknown parser")
	}

	return p.Parse(os.Args[2], os.Args[3])
	//return nil
}

func main(){
	if err := run(); err != nil {
		log.Fatalf("error: %v\n", err)
	}
}

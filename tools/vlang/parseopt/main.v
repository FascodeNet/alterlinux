module main

import os
import regex

// textがptnに完全に一致した場合にtrueを返す
fn grepq(ptn string, text string) (bool){
	mut re := regex.regex_opt(ptn) or {exit(1)}
	result := re.matches_string(text)
	return result
}
// in_textのptnに一致した部分をrepl_textに置き換えます
fn seds(in_text string, ptn string, repl_text string)(string){
	mut re := regex.regex_opt(ptn) or{exit(1)}
	return re.replace(in_text, repl_text)
}

fn regex_find(ptn string, in_text string) []int{
	mut re := regex.regex_opt(ptn) or {exit(1)}
	return re.find_all(in_text)
}

// This is an invalid argument.
fn invalid_arg(arg string){
	eprintln("${arg}は不正なオプションです。-hで使い方を確認してください。")
	exit(2)
}

fn missing_arg(arg string){
	eprintln("${arg}の引数が指定されていません。")
	exit(1)
}

fn invalid_usage(){
	eprintln("parseoptの間違った使い方です。")
	exit(3)
}


fn main (){
	mut long_with_arg := []string{}
	mut short_with_arg := []string{}
	mut long := []string{}
	mut short := []string{}

	// 引数を取得
	//filename := os.args[0]
	mut args := os.args[1..]
	mut argc := 1

	// 使い方を表示
	if args.len == 0{
		eprintln("parseopt parses and sorts the arguments.Use it with eval in shell scripts.")
		eprintln(" Usage : parseopt LONG=\"<LONG OPTIONS>\" SHORT=\"<SHORT OPTIONS>\" -- \"\${@}\"")
		eprintln("Example: parseopt LONG=\"help,path:\" SHOTR=\"hs:\" -- \"\${@}\"")
		exit(1)
	}

	// オプションの定義を取得
	for mut arg in args{
		mut temp_array := []string{}
		if arg.starts_with("LONG=") {
			temp_array = arg.replace("LONG=", "").split(",")
			for mut chr in temp_array{
				if chr.ends_with(":"){
					long_with_arg << seds(chr, ":$", "")
				}else{
					long << chr
				}
			}
		}else if arg.starts_with("SHORT="){
			//println("There is nothing")
			temp_array = arg.replace("SHORT=", "").split("")
			for cnt:=0; cnt<=temp_array.len - 1;cnt++{
				if cnt == temp_array.len-1 || temp_array[cnt+1] != ":"{
					short << temp_array[cnt]
				}else{
					short_with_arg << temp_array[cnt]
					cnt++
				}
			}
		}else if arg == "--"{
			argc++
			break
		}else{
			invalid_usage()
		}
		argc++
	}

	/*
	println(os.args[argc+1..])
	println(short)
	println(long)
	println(short_with_arg)
	println(long_with_arg)
	*/

	args = os.args[argc..]

	mut outarg := []string{}
	mut noarg := []string{}
	mut temp_str := ""
	mut nextarg := ""

	for cnt:=0; cnt<=args.len - 1; cnt++{
		mut arg := args[cnt]
		if cnt == args.len-1{
			nextarg=""
		}else{
			nextarg=args[cnt+1]
		}

		if arg == "--"{
			argc++
			noarg << os.args[argc..]
			break
		}else if arg.starts_with("--"){
			//println("$arg is long option")
			temp_str=seds(arg, "^--", "")
			if temp_str in long_with_arg{
				if nextarg == "" || nextarg.starts_with("-"){
					missing_arg(arg)
				}
				outarg <<arg
				outarg << nextarg
				cnt+=1
			}else if temp_str in long{
				outarg << arg
			}else{
				invalid_arg(arg)
			}
		} else if arg.starts_with("-"){
			temp_str = seds(arg, "^-", "")
			//mut shift:=0
			for chr in temp_str.split(""){
				if chr in short_with_arg{
					if grepq("^.+${chr}" , arg) && ! nextarg.starts_with("-") && nextarg != "" {
						outarg << "-${chr}"
						outarg << nextarg
						cnt++
					}else{
						missing_arg("-${chr}")
					}
				}else if chr in short{
					outarg << "-${chr}"
				}else{
					invalid_usage
				}
			}
		}else{
			noarg << arg
		}
		
	}

	outarg << "--"
	outarg << noarg

	mut outstr := ""
	mut cnt := 0

	for mut str in outarg{
		
		// 空白文字が1つ以上含まれていたら
		if regex_find(" ", str).len != 0{
			// "で囲む
			outstr += "\"$str\""
		}else{
			outstr += "$str"
		}
		if cnt != outarg.len{
			outstr += " "
		}
		cnt++
	}
	println(outstr)
}

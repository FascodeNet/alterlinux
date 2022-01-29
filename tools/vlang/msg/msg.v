// Usage: msg [options] [label] [text]

import colormsg as cm
import os
import flag
import strings as str
//import cli


struct MsgFormat{
	mut: 
		label string
		labelconf cm.ColoredText
		labelsize int

		appname string
		appnameconf cm.ColoredText

		body []string
		bodyconf cm.ColoredText

		noadjust bool 
		noappname bool
		nolabel bool
		nocolor bool
}


fn (fm MsgFormat) print () (string){
	mut print := ""

	// ラベルの空白調整
	mut label_space := fm.labelsize - fm.label.len
	mut label := ""
	if label_space > 0 {
		//for i in 0..label_space{
		//	label += " "
		//}
		label += str.repeat_string(" ", label_space)
	}
	label += fm.label + " "

	// appnameを囲う
	mut appname := "[${fm.appname}]"

	for bdlines in fm.body{
		for bd in bdlines.split("\n"){
			print += fm.appnameconf.print(appname) + fm.labelconf.print(label) + fm.bodyconf.print(bd)
		}
	}
	return print
}

fn get_chr_byte(s string) ?byte{
	if s.len > 1{
		return none
	}else{
		return s.bytes()[0]
	}
}

fn print_to(str string, path string){
	if path == "stdout"{
			print(str)
			return
	}else if path == "stderr"{
			eprint(str)
			return
	}

	mut output := os.stdout()
	if os.exists(path){
		output = os.open_file(path, "a")or{
			print_msg_error("Failed to open $path")
			return
		}
	}else{
		output = os.create(path)or{
			print_msg_error("Failed to create $path")
			return
		}
	}
	
	output.write_string(str)or{}
}

fn main(){
	//== Parse args formats ==\\
	mut fp := flag.new_flag_parser(os.args)
	fp.application("msg")
	fp.limit_free_args_to_at_least(2) or {}
	fp.description("Display a message with a colored app name and message type label")
	fp.args_description = "[type] [message]"
	fp.footers << [
		"", 
		"Type:",
		"  info                      General message",
		"  warn                      Warning message",
		"  error                     Error message",
		"  debug                     Debug message"
	]
	fp.skip_executable()
	//fp.disable_help = true
	//fp.disable_version = true

	appname   := fp.string ("appname", get_chr_byte("a")?, "msg", "Specify the app name")
	labelsize := fp.int("labelsize", get_chr_byte("s")?, 7, "Specifies the label space")
	output    := fp.string("output", get_chr_byte("p")?, "stderr", "Specify the output destination\n                            standard output: stdout\n                            error output   : stderr")
	//custom_label := fp.string ("label", get_chr_byte("l")?, "", "Specify the label")
	//custom_labelcolor := cm.get_color_from_str(fp.string("label-color", 0, "default", "Specify the color of label"))?

	nocolor   := fp.bool("nocolor"  , 0, false, "Do not colored output")
	nolabel   := fp.bool("nolabel"  , 0, false, "Do not output label")
	noappname := fp.bool("noappname", 0, false, "Do not output app name")
	noadjust  := fp.bool("noadjust" , 0, false, "Do not adjust the width of the label")

	// 最終処理
    args := fp.finalize() or {
        //print_msg_error("You should at least 2 args")
		print(fp.usage())
		exit(1)
    }

	// ラベルタイプ、本文を取得
	mut msg_type := args[0]
	mut body     := args[1..]

	//== Create formats ==\\
	// 本文（共通）
	mut common_body := cm.ColoredText{
		//font: cm.Color.default
		bg:   cm.Color.default
		decos: []cm.Deco{}
		newline: true
	}

	// アプリ名（共通）
	mut common_appname := cm.ColoredText{
		//font: cm.Color.default
		//font: cm.get_color_from_str("blue") or { exit(1) }
		bg:   cm.Color.default
		decos: []cm.Deco{}
		newline: false
	}

	// info
	mut format_info := MsgFormat{
		label: "INFO"
		labelsize: labelsize
		labelconf: cm.ColoredText{
			font: cm.Color.green
			newline: false
		}

		appname: appname
		appnameconf : common_appname

		body: []
		bodyconf: common_body
	
		noadjust: noadjust
		noappname: noappname
		nolabel: nolabel
		nocolor: nocolor
	}

	mut format_warn := MsgFormat{
		label: "WARN"
		labelsize: labelsize
		labelconf: cm.ColoredText{
			font: cm.Color.yellow
			newline: false
		}
		
		appname: appname
		appnameconf : common_appname

		body: []
		bodyconf: common_body
	
		noadjust: noadjust
		noappname: noappname
		nolabel: nolabel
		nocolor: nocolor
	}

	mut format_error := MsgFormat{
		label: "ERROR"
		labelsize: labelsize
		labelconf: cm.ColoredText{
			font: cm.Color.red
			newline: false
		}

		appname: appname
		appnameconf : common_appname

		body: []
		bodyconf: common_body

		noadjust: noadjust
		noappname: noappname
		nolabel: nolabel
		nocolor: nocolor
	}

	mut format_debug := MsgFormat{
		label: "DEBUG"
		labelsize: labelsize
		labelconf: cm.ColoredText{
			font: cm.Color.magenta
			newline: false
		}

		appname: appname
		appnameconf : common_appname

		body: []
		bodyconf: common_body

		noadjust: noadjust
		noappname: noappname
		nolabel: nolabel
		nocolor: nocolor
	}



	//== Run ==\\
	match msg_type{
		"info"{
			format_info.body=body
			//print(format_info.print())
			print_to(format_info.print(), output)
		}
		"warn"{
			format_warn.body=body
			//print(format_warn.print())
			print_to(format_warn.print(), output)
		}
		"error"{
			format_error.body=body
			//print(format_error.print())
			print_to(format_error.print(), output)
		}
		"debug"{
			format_debug.body=body
			//print(format_debug.print())
			print_to(format_debug.print(), output)
		}
		else{
			print_msg_error("Unknown message type (${msg_type})")
		}
	}
	
}


fn print_msg_error(str string){
	mut msg_error := MsgFormat{
		label: "ERROR"
		labelsize: 6
		labelconf: cm.ColoredText{
			font: cm.Color.red
			newline: false
		}

		appname: "msg"
		appnameconf : cm.ColoredText{
			//font: cm.Color.default
			//font: cm.get_color_from_str("blue") or { exit(1) }
			//bg:   cm.Color.default
			//decos: []cm.Deco{}
			newline: false
		}

		body: [str]
		bodyconf: cm.ColoredText{
			//font: cm.Color.default
			//bg:   cm.Color.default
			//decos: []cm.Deco{}
			newline: true
		}
	}
	eprint(msg_error.print())
	exit(1)
}

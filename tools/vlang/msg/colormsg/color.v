module colormsg

pub enum Color {
	black   = 0
	red     = 1
	green   = 2
	yellow  = 3
	blue    = 4
	magenta = 5
	cyan    = 6
	white   = 7
	default = 9

	gray           = 10
	bright_red     = 11
	bright_green   = 12
	bright_yellow  = 13
	bright_blue    = 14
	bright_magenta = 15
	bright_cyan    = 16
	bright_white   = 17
}

pub fn get_font_color(color Color) int{
	if int(color) < 8{
		return 30 + int(color)
	}else{
		return 80 + int(color)
	}
}

pub fn get_bg_color(color Color) int{
	return get_font_color(color) + 10
}


pub fn get_color_from_str(str string) ?Color{
	match str{
		"black"          { return .black          }
		"red"            { return .red            }
		"green"          { return .green          }
		"yellow"         { return .yellow         }
		"blue"           { return .blue           }
		"maganta"        { return .magenta        }
		"cyan"           { return .cyan           }
		"white"          { return .white          }
		"default"        { return .default        }
		"gray"           { return .gray           }
		"bright_red"     { return .bright_red     }
		"bright_green"   { return .bright_green   }
		"bright_yellow"  { return .bright_yellow  }
		"bright_blue"    { return .bright_blue    }
		"bright_magenta" { return .bright_magenta }
		"bright_cyan"    { return .bright_cyan    }
		"bright_white"   { return .bright_white   }
		else             { return none            }
	}
}

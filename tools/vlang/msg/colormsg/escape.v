module colormsg

pub fn ecs_reset() string{
	return "\e[m"
}

pub fn ecs_num(n int) string{
	return "\e[${n}m"
}

pub fn ecs_font_color(color Color) string{
	return ecs_num(get_font_color(color))
}

pub fn ecs_bg_color(color Color) string{
	return ecs_num(get_bg_color(color))
}

pub fn ecs_deco(deco Deco) string{
	return ecs_num(int(deco))
}

pub struct ColoredText{
	font Color = .default
	bg   Color = .default
	decos []Deco 
	newline bool = true
}

pub fn (tx ColoredText) print (body string) (string){
	mut output := []string {}
	output << [ecs_font_color(tx.font), ecs_bg_color(tx.bg)]
	for deco in tx.decos{
		output << ecs_deco(deco)
	}
	output << body
	output << ecs_reset()
	if tx.newline{
		output << "\n"
	}
	return output.join("")
}

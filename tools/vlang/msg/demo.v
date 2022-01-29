import colormsg as cm

fn main(){
	// 方法1
	print(cm.ecs_font_color(cm.Color.red) + cm.ecs_deco(cm.Deco.underline) + "Hello World\n" + cm.ecs_reset())

	// 方法2
	mut ctext := cm.ColoredText{
		font: .red
		bg: .default
		decos: [
			.underline
		]
		newline: true
	}
	print(ctext.print("Hello World"))
}

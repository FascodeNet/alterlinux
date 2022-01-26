module colormsg

pub enum Deco{
	// リセット
	reset  = 0
	// 太く
	bold   = 1
	// 薄く
	faint  = 2
	// イタリック
	italic = 3
	// 下線
	underline = 4
	// 遅く点滅
	slow_blink = 5
	// 速く点滅（サポート少）
	rapid_blink = 6
	// 反転（背景と文字色）
	invert = 7
	// 隠す
	hide = 8
	// 打ち消し線
	strike = 9
}


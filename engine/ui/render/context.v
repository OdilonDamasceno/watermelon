module render

import ui { Rect, Window }

pub struct Context {
	Rect
pub mut:
	window &Window
}

pub fn new_context(window &Window) Context {
	rect := Rect{
		x:      0
		y:      0
		width:  window.size.width
		height: window.size.height
	}

	return Context{
		Rect:   rect
		window: window
	}
}

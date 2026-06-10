module render

import ui { Window }

pub struct Canvas {
mut:
	window ?&Window
}

pub fn new_canvas(window &Window) Canvas {
	return Canvas{
		window: window
	}
}

pub fn (mut c Canvas) canvas_draw_rect(x u8, y u8, width u8, height u8) ! {
	if mut w := c.window {
		w.draw_rect(x, y, width, height)!
		return
	}
	return error('Canvas has no window attached')
}

pub fn (mut c Canvas) canvas_draw_line(x1 u8, y1 u8, x2 u8, y2 u8) ! {
	if mut w := c.window {
		w.draw_line(x1, y1, x2, y2)!
		return
	}
	return error('Canvas has no window attached')
}

pub fn (mut c Canvas) canvas_clear() {
	if mut w := c.window {
		w.clear()
	}
}

pub fn (mut c Canvas) canvas_update() ! {
	if mut w := c.window {
		w.refresh()!
		return
	}
	return error('Canvas has no window attached')
}

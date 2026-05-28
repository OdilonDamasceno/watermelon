module ui

import drivers { Display, new_display }

@[heap]
pub struct Window {
mut:
	display Display
pub:
	size Size
}

@[params]
pub struct WindowConfig {
pub:
	size Size = Size{
		width:  128
		height: 64
	}
}

pub fn new_window(c WindowConfig) !&Window {
	mut display := new_display(width: c.size.width, height: c.size.height) or {
		return error('Failed to create display: ${err}')
	}

	return &Window{
		display: display
		size:    c.size
	}
}

pub fn (mut w Window) size() Size {
	return w.size
}

pub fn (mut w Window) clear() {
	w.display.ch.buffer.clear_buffer()
}

pub fn (mut w Window) refresh() ! {
	w.display.ch.flush() or { return error('Failed to refresh display: ${err}') }
}

pub fn (mut w Window) draw_pixel(x u8, y u8) ! {
	w.display.ch.buffer.set_pixel(x, y, true) or { return error('Failed to set pixel: ${err}') }
}

pub fn (mut w Window) draw_line(x1 u8, y1 u8, x2 u8, y2 u8) ! {
	w.display.ch.buffer.draw_line(x1, y1, x2, y2) or { return error('Failed to draw line: ${err}') }
}

pub fn (mut w Window) draw_rect(x u8, y u8, width u8, height u8) ! {
	w.display.ch.buffer.draw_rectangle(x, y, width, height) or {
		return error('Failed to draw rectangle: ${err}')
	}
}

pub fn (mut w Window) draw_circle(x u8, y u8, radius u8) ! {
	w.display.ch.buffer.draw_circle(x, y, radius) or { return error('Failed to draw circle: ${err}') }
}

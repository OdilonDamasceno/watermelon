module drivers

import uapi { I2c }

pub struct Ch1116 {
pub:
	i2c    I2c
	width  u8
	height u8
pub mut:
	buffer DisplayBuffer
}

@[params]
pub struct Ch1116Config {
pub:
	i2c    I2c
	width  u8 = 128
	height u8 = 64
}

struct DisplayBuffer {
mut:
	ram_local [1024]u8
}

pub fn new_ch1116(c Ch1116Config) !&Ch1116 {
	mut ch := &Ch1116{
		i2c:    c.i2c
		width:  c.width
		height: c.height
	}
	ch.reset() or { return error('Failed to clear the display during initialization: ${err}') }
	ch.turn_on() or { return error('Failed to initialize the display: ${err}') }
	return ch
}

fn (mut ch Ch1116) write_command(command u8) ! {
	mut buffer := []u8{cap: 2}
	buffer << 0x00
	buffer << command
	ch.i2c.write(buffer) or { return error('Failed to write command to the display: ${err}') }
}

fn (mut ch Ch1116) select_page(page u8) ! {
	ch.write_command(0xB0 + page)!
	ch.write_command(0x00)!
	ch.write_command(0x10)!
}

pub fn (mut ch Ch1116) turn_off() ! {
	mut display_off := []u8{cap: 4}

	display_off << 0x00

	display_off << 0xAD
	display_off << 0x8A

	display_off << 0xAE

	ch.i2c.write(display_off) or { return error('Failed to turn off the display: ${err}') }
}

pub fn (mut ch Ch1116) turn_on() ! {
	mut display_on := []u8{cap: 10}

	display_on << 0x00
	display_on << 0xAD
	display_on << 0x8B

	display_on << 0xA1
	display_on << 0xC8

	display_on << 0xAF

	ch.i2c.write(display_on) or { return error('Failed to turn on the display: ${err}') }
}

pub fn (mut ch Ch1116) set_contrast(contrast u8) ! {
	mut buffer_contrast := []u8{cap: 3}
	buffer_contrast << 0x00
	buffer_contrast << 0b10000001
	buffer_contrast << contrast

	ch.i2c.write(buffer_contrast) or { return error('Failed to set display contrast: ${err}') }
}

pub fn (mut ch Ch1116) get_status() !u8 {
	mut status := []u8{cap: 1}
	status << 0x01
	ch.i2c.read(status) or { return error('Failed to read the display status: ${err}') }
	return status[0]
}

pub fn (mut ch Ch1116) reset() ! {
	ch.buffer.clear_buffer()
	for page in 0 .. 8 {
		ch.write_command(0xB0 + page)!
		ch.write_command(0x00)!
		ch.write_command(0x10)!

		mut buffer_clear := []u8{cap: 132}
		buffer_clear << 0x40
		for _ in 0 .. 132 {
			buffer_clear << 0x00
		}
		ch.i2c.write(buffer_clear) or { return error('Failed to clear the display: ${err}') }
	}
}

pub fn (mut ch Ch1116) flush() ! {
	for page in 0 .. 8 {
		ch.select_page(u8(page)) or { return error('Failed to select page ${page}: ${err}') }

		mut page_data := []u8{cap: 129}
		page_data << 0x40

		start := page * 128
		end := start + 128
		chunk := ch.buffer.ram_local[start..end]

		page_data << chunk

		ch.i2c.write(page_data) or {
			return error('Falha ao enviar a página ${page} para o display')
		}
	}
}

/*----------------------------------------------------------------------------------
------------------------------------------------------------------------------------
----------------------------------------------------------------------------------*/

pub fn (mut buffer DisplayBuffer) set_pixel(x u8, y u8, on bool) ! {
	page := int(y) / 8
	bit_position := int(y) % 8
	x_pos := int(x)

	idx := page * 128 + x_pos

	if on {
		buffer.ram_local[idx] |= u8(1 << bit_position)
	} else {
		buffer.ram_local[idx] &= ~u8(1 << bit_position)
	}
}

pub fn (mut buffer DisplayBuffer) draw_line(x1 u8, y1 u8, x2 u8, y2 u8) ! {
	if x1 > 127 || y1 > 63 || x2 > 127 || y2 > 63 {
		return error('Coordenadas fora dos limites do display')
	}

	mut x0 := i16(x1)
	mut y0 := i16(y1)
	x_end := i16(x2)
	y_end := i16(y2)

	dx := if x_end > x0 { x_end - x0 } else { x0 - x_end }
	dy := if y_end > y0 { y0 - y_end } else { y_end - y0 }

	sx := if x0 < x_end { i16(1) } else { i16(-1) }
	sy := if y0 < y_end { i16(1) } else { i16(-1) }

	mut err := dx + dy

	for {
		buffer.set_pixel(u8(x0), u8(y0), true) or {
			return error('Failed to set pixel at (${x0}, ${y0}): ${err}')
		}

		if x0 == x_end && y0 == y_end {
			break
		}

		e2 := 2 * err
		if e2 >= dy {
			err += dy
			x0 += sx
		}
		if e2 <= dx {
			err += dx
			y0 += sy
		}
	}
}

pub fn (mut buffer DisplayBuffer) clear_buffer() {
	for i in 0 .. buffer.ram_local.len {
		buffer.ram_local[i] = 0x00
	}
}

pub fn (mut buffer DisplayBuffer) draw_rectangle(x1 u8, y1 u8, width u8, height u8) ! {
	if x1 > 127 || y1 > 63 {
		return error('Coordinates of the top-left corner are out of display bounds')
	}
	if width == 0 || height == 0 {
		return error('Rectangle width and height must be greater than zero')
	}

	x_end := int(x1) + int(width)
	y_end := int(y1) + int(height)
	if x_end > 128 || y_end > 64 {
		return error('Dimensions of the rectangle exceed the display bounds')
	}

	x2 := u8(x_end - 1)
	y2 := u8(y_end - 1)

	buffer.draw_line(x1, y1, x2, y1) or { return error('Failed to draw top edge of the rectangle: ${err}') }
	buffer.draw_line(x2, y1, x2, y2) or { return error('Failed to draw right edge of the rectangle: ${err}') }
	buffer.draw_line(x2, y2, x1, y2) or { return error('Failed to draw bottom edge of the rectangle: ${err}') }
	buffer.draw_line(x1, y2, x1, y1) or { return error('Failed to draw left edge of the rectangle: ${err}') }
}

pub fn (mut buffer DisplayBuffer) draw_circle(cx u8, cy u8, radius u8) ! {
	ccx := i16(cx)
	ccy := i16(cy)
	r := i16(radius)

	mut x := r
	mut y := i16(0)

	mut err := i16(1 - r)

	for x >= y {
		points := [
			[ccx + x, ccy + y],
			[ccx + y, ccy + x],
			[ccx - y, ccy + x],
			[ccx - x, ccy + y],
			[ccx - x, ccy - y],
			[ccx - y, ccy - x],
			[ccx + y, ccy - x],
			[ccx + x, ccy - y],
		]

		for pt in points {
			px := pt[0]
			py := pt[1]

			if px >= 0 && px <= 127 && py >= 0 && py <= 63 {
				buffer.set_pixel(u8(px), u8(py), true) or {}
			}
		}

		y++
		if err < 0 {
			err += 2 * y + 1
		} else {
			x--
			err += 2 * (y - x) + 1
		}
	}
}

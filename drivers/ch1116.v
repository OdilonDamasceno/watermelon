module drivers

import uapi { I2c }

struct DisplayBuffer {
mut:
	ram_local [1024]u8 // 8x128
}

pub struct Ch1116 {
pub:
	i2c    I2c
	width  u8
	height u8
mut:
	buffer DisplayBuffer
}

@[params]
pub struct Ch1116Config {
pub:
	i2c    I2c
	width  u8 = 128
	height u8 = 64
}

pub fn Ch1116.new(c Ch1116Config) Ch1116 {
	mut ch := Ch1116{
		i2c:    c.i2c
		width:  c.width
		height: c.height
	}
	ch.clear() or { panic('Failed to clear the display during initialization') }
	ch.turn_on() or { panic('Failed to initialize the display') }
	return ch
}

fn (mut ch Ch1116) write_command(command u8) {
	mut buffer := []u8{cap: 2}
	buffer << 0x00
	buffer << command
	ch.i2c.write(buffer) or { panic('Failed to write command to the display') }
}

fn (mut ch Ch1116) select_page(page u8) {
	ch.write_command(0xB0 + page)
	ch.write_command(0x04)
	ch.write_command(0x10)
}

pub fn (mut ch Ch1116) set_pixel(x u8, y u8, on bool) ! {
	if x > ch.width || y > ch.height {
		return error('Coordenadas fora dos limites do display')
	}

	page := int(y) / 8
	bit_position := int(y) % 8
	x_pos := int(x)

	idx := page * 128 + x_pos

	if on {
		ch.buffer.ram_local[idx] |= u8(1 << bit_position)
	} else {
		ch.buffer.ram_local[idx] &= ~u8(1 << bit_position)
	}
}

pub fn (mut ch Ch1116) turn_off() ! {
	mut display_off := []u8{cap: 4}

	display_off << 0x00

	display_off << 0xAD
	display_off << 0x8A

	display_off << 0xAE

	ch.i2c.write(display_off) or { panic('Failed to turn off the display') }
}

pub fn (mut ch Ch1116) turn_on() ! {
	mut display_on := []u8{cap: 4}

	display_on << 0x00

	display_on << 0xAD
	display_on << 0x8B

	display_on << 0xAF

	ch.i2c.write(display_on) or { panic('Failed to turn on the display') }
}

pub fn (mut ch Ch1116) set_contrast(contrast u8) ! {
	mut buffer_contrast := []u8{cap: 3}
	buffer_contrast << 0x00
	buffer_contrast << 0b10000001
	buffer_contrast << contrast

	ch.i2c.write(buffer_contrast) or { panic('Failed to set display contrast') }
}

pub fn (mut ch Ch1116) get_status() u8 {
	mut status := []u8{cap: 1}
	status << 0x01
	ch.i2c.read(status) or { panic('Failed to read the display status') }
	return status[0]
}

/*----------------------------------------------------------------------------------
------------------------------------------------------------------------------------
----------------------------------------------------------------------------------*/

pub fn (mut ch Ch1116) show() ! {
	for page in 0 .. 8 {
		ch.select_page(u8(page))

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

pub fn (mut ch Ch1116) draw_line(x1 u8, y1 u8, x2 u8, y2 u8) ! {
	if x1 > 127 || y1 > 63 || x2 > 127 || y2 > 63 {
		return error('Coordenadas fora dos limites do display')
	}

	mut x0 := i16(x1)
	mut y0 := i16(y1)
	x_end := i16(x2)
	y_end := i16(y2)

	// Calcula diferenças absolutas usando apenas inteiros
	dx := if x_end > x0 { x_end - x0 } else { x0 - x_end }
	dy := if y_end > y0 { y0 - y_end } else { y_end - y0 } // Note: y0 - y_end para garantir o valor negativo clássico do algoritmo

	// Direção do incremento
	sx := if x0 < x_end { i16(1) } else { i16(-1) }
	sy := if y0 < y_end { i16(1) } else { i16(-1) }

	mut err := dx + dy

	for {
		// Desenha o pixel atual
		ch.set_pixel(u8(x0), u8(y0), true) or { panic('Failed to set pixel at (${x0}, ${y0})') }

		// Se chegou ao fim da linha, sai do ciclo
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

pub fn (mut ch Ch1116) clear_buffer() {
	for i in 0 .. ch.buffer.ram_local.len {
		ch.buffer.ram_local[i] = 0x00
	}
}

pub fn (mut ch Ch1116) draw_rectangle(x1 u8, y1 u8, x2 u8, y2 u8) ! {
	ch.draw_line(x1, y1, x2, y1) or { panic('Failed to draw top edge of rectangle') }
	ch.draw_line(x1, y2, x2, y2) or { panic('Failed to draw bottom edge of rectangle') }
	ch.draw_line(x1, y1, x1, y2) or { panic('Failed to draw left edge of rectangle') }
	ch.draw_line(x2, y1, x2, y2) or { panic('Failed to draw right edge of rectangle') }
}

pub fn (mut ch Ch1116) draw_circle(cx u8, cy u8, radius u8) ! {
	if cx > 127 || cy > 63 {
		return error('Coordenadas do centro fora dos limites do display')
	}

	mut x := i16(radius)
	mut y := i16(0)
	mut err := i16(0)

	for x >= y {
		ch.set_pixel(u8(cx + x), u8(cy + y), true) or {
			panic('Failed to set pixel at (${cx + x}, ${cy + y})')
		}
		ch.set_pixel(u8(cx + y), u8(cy + x), true) or {
			panic('Failed to set pixel at (${cx + y}, ${cy + x})')
		}
		ch.set_pixel(u8(cx - y), u8(cy + x), true) or {
			panic('Failed to set pixel at (${cx - y}, ${cy + x})')
		}
		ch.set_pixel(u8(cx - x), u8(cy + y), true) or {
			panic('Failed to set pixel at (${cx - x}, ${cy + y})')
		}
		ch.set_pixel(u8(cx - x), u8(cy - y), true) or {
			panic('Failed to set pixel at (${cx - x}, ${cy - y})')
		}
		ch.set_pixel(u8(cx - y), u8(cy - x), true) or {
			panic('Failed to set pixel at (${cx - y}, ${cy - x})')
		}
		ch.set_pixel(u8(cx + y), u8(cy - x), true) or {
			panic('Failed to set pixel at (${cx + y}, ${cy - x})')
		}
		ch.set_pixel(u8(cx + x), u8(cy - y), true) or {
			panic('Failed to set pixel at (${cx + x}, ${cy - y})')
		}

		y += 1
		if err <= 0 {
			err += 2 * y + 1
		} else {
			x -= 1
			err += 2 * (y - x) + 1
		}
	}
}

pub fn (mut ch Ch1116) clear() ! {
	ch.clear_buffer()
	for page in 0 .. 8 {
		ch.write_command(0xB0 + page)
		ch.write_command(0x00)
		ch.write_command(0x10)

		mut buffer_clear := []u8{cap: 132}
		buffer_clear << 0x40
		for _ in 0 .. 132 {
			buffer_clear << 0x00
		}
		ch.i2c.write(buffer_clear) or { panic('Failed to clear the display') }
	}
}

module main

import uapi { I2c }
import drivers { Ch1116 }

fn main() {
	i2c := I2c.new('/dev/i2c-2', 0x3c) or { panic('Failed to open I2C device: ${err}') }
	mut ch := Ch1116.new(i2c: i2c)
	ch.set_contrast(255) or { panic('Failed to set breathing light: ${err}') }
	ch.draw_rectangle(0, 0, 127, 63) or { panic('Failed to draw rectangle: ${err}') }
	ch.show() or { panic('Failed to update display: ${err}') }
}

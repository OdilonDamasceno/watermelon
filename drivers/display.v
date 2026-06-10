module drivers

import uapi { I2c }

pub struct Display {
pub:
	height u8
	width  u8
pub mut:
	ch &Ch1116
}

@[params]
pub struct DConfig {
pub:
	width  u8 = 128
	height u8 = 64
}

pub fn new_display(c DConfig) !&Display {
	i2c := I2c.new('/dev/i2c-2', 0x3c) or { return error('Failed to open I2C device: ${err}') }
	mut ch := new_ch1116(i2c: i2c) or {
		return error('Failed to initialize CH1116 display: ${err}')
	}

	dp := &Display{
		height: c.height
		width:  c.width
		ch:     ch
	}

	return dp
}

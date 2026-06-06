module drivers

pub struct Display {
	addr u8
pub:
	height int
	width  int
}

pub fn Display.new(addr u8, height int, width int) Display {
    dp = Display{
        addr:   addr
        height: height
        width:  width
    }

   	i2c := I2c.new('/dev/i2c-2', 0x3c) or { panic('Failed to open I2C device: ${err}') }
	mut ch := Ch1116.new(i2c: i2c)

	return dp
}

module drivers

pub struct Display {
	addr u8
pub:
	height int
	width  int
}

pub fn Display.new(addr u8, height int, width int) Display {
    dp := Display{
        addr:   addr
        height: height
        width:  width
    }

	return dp
}

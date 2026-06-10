
module ui

pub struct Constraint {
pub mut:
	min_width  u8
	max_width  u8
	min_height u8
	max_height u8
}

pub struct Offset {
pub mut:
	x u8
	y u8
}

pub struct Size {
pub mut:
	width  u8
	height u8
}

pub struct Rect {
	Size
	Offset
}

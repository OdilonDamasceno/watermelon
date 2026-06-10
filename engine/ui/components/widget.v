module components

import render { Canvas, Context, new_canvas }
import ui { Rect }

pub struct Widget {
	Canvas
	Rect
pub mut:
	context Context
}

fn new_widget(context Context) Widget {
	canvas := new_canvas(context.window)

	return Widget{
		Canvas:  canvas
		Rect:    context.Rect
		context: context
	}
}

fn (mut w Widget) render(ctx Context) {}

fn (mut w Widget) set_state(run fn () !) ! {
	run()!
	w.canvas_update()!
}

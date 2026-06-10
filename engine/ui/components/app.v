module components

import render { Context, new_context }
import ui { new_window }

pub struct App {
	Widget
pub mut:
	child ?Widget
}

@[params]
pub struct AppProps {
}

pub fn new_app(p AppProps) &App {
	mut window := new_window() or { panic('Failed to create window: ${err}') }
	mut ctx := new_context(window)
	app := new_widget(ctx)
	return &App{
		Widget: app
	}
}

pub fn (mut app App) render(mut ctx Context) ! {
	app.canvas_draw_rect(0, 0, 10, 10)!
	if mut child := app.child {
		child.render(ctx)
		app.child = child
	}
}

pub fn run_app(mut app App) ! {
	app.render(mut app.context)!
	app.set_state(fn () ! {})!
}

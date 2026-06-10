module main

import engine.ui.components { new_app, run_app }

fn main() {
	mut app := new_app()
	run_app(mut app) or {
		eprintln('run_app failed: ${err}')
	}
}

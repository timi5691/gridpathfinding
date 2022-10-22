module main

import gg
import gx
import mystructs
import input
import update
import draw
import grid2d



fn main() {
	mut app := &mystructs.App{gg: 0}
	app.cols = 20
	app.rows = 15
	app.cell_size = 32
	
	app.gg = gg.new_context(
		bg_color: gx.black
		width: app.cols*app.cell_size
		height: app.rows*app.cell_size
		window_title: "PATH FINDING"

		init_fn: init
		frame_fn: frame
		click_fn: input.on_mouse_down
		unclick_fn: input.on_mouse_up
		keydown_fn: input.on_key_down

		user_data: app
	)
	app.gg.run()
}


fn init(mut app mystructs.App) {
	app.grid = grid2d.create_grid(app.cols, app.rows, app)
}

fn frame(mut app mystructs.App) {
	update.update(mut app)
	draw.draw(app)
}


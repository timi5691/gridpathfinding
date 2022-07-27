module main

import gg
import gx
// import time
// import math
// import rand
// import rand.seed
import grid_path_finding as gpfd

struct App {
mut: 
	gg &gg.Context
	debug string

	grid_data gpfd.GridData
	
	// this is to test with start point, in this example i can change the start by right mouse click, 
	// left click to select end point, press o to change optimized 
	start int
	path []gpfd.PixelPos
	optimized bool = true

	follower gpfd.PathFollower
}

fn main() {
	mut app := &App{gg: 0}

	app.gg = gg.new_context(
		// bg_color: gx.black
		width: 64*9
		height: 64*8
		window_title: "TEST GRID PATH FINDING"

		init_fn: init
		frame_fn: frame
		click_fn: on_click
		keydown_fn: on_key_down

		user_data: app
	)

	app.gg.run()
}


fn init(mut app App){
	// seed_array := seed.time_seed_array(2)
	// rand.seed(seed_array)
	
	// third step: create a grid and store it to a variable
	app.grid_data = gpfd.create_grid_data(9, 8, 64)

	// i use this array to init grid, 0 mean walkable, 1 is not walkable
	mut grid_init := [
		0, 0, 1, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 1, 0,
		0, 0, 1, 0, 1, 1, 0, 0, 0,
		0, 0, 1, 1, 1, 0, 0, 0, 0,
		0, 0, 0, 0, 1, 0, 0, 0, 0,
		0, 0, 0, 0, 1, 0, 0, 1, 0,
		0, 0, 0, 1, 1, 0, 0, 0, 0,
		1, 0, 0, 0, 0, 0, 0, 0, 0,
	]

	// set walkable for grid data
	for id in 0..grid_init.len {
		if grid_init[id] == 1 {
			app.grid_data.set_cell_walkable(id, false)
		}
	}

	app.follower.pos = gpfd.PixelPos{x: 3*64 + 32, y: 1*64 + 32}
	app.follower.after_finished_do = 0 // 0: stop, 1: reapeat, 2: reverse
}


fn on_click(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {
			fl := app.follower
			id_start := app.grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
			// id_start := app.start
			end := app.grid_data.get_id_from_pixel_pos(int(x), int(y))

			app.path = app.grid_data.path_finding(id_start, end, app.optimized)
			
			app.follower.set_path(app.path, app.grid_data)
			app.follower.start_move()
		}
		.right {
			mut fl := &app.follower
			if fl.status == 0 {
				id_click := app.grid_data.get_id_from_pixel_pos(int(x), int(y))
				grid_pos_click := app.grid_data.cell_id_to_gridpos(id_click)
				pos_click := app.grid_data.gridpos_to_pixel_pos(grid_pos_click)
				half_cellsize := app.grid_data.cell_size/2
				fl.pos.x = pos_click.x + half_cellsize
				fl.pos.y = pos_click.y + half_cellsize
			}
			// app.start = app.grid_data.get_id_from_pixel_pos(int(x), int(y))
		}
		else {}
	}
	
	
}

fn on_key_down(key gg.KeyCode, m gg.Modifier, mut app App) {
	app.debug = key.str()
	match key {
		.escape {
			app.gg.quit()
		}
		.o {
			if app.optimized {
				app.optimized = false
			} else {
				app.optimized = true
			}
			app.debug = app.optimized.str()
		}
		else {}
	}
}

fn frame(mut app App) {
	ctx := app.gg
	ctx.begin()

	// draw walkable_cells and cell_ids
	for row in 0..app.grid_data.rows {
		for col in 0..app.grid_data.cols {
			gridpos := gpfd.GridPos{col: col row: row}
			cell_id := app.grid_data.gridpos_to_cell_id(gridpos)
			cell_pos := app.grid_data.gridpos_to_pixel_pos(gridpos)
			txt := cell_id.str()
			// draw walkable cells
			if app.grid_data.is_cell_walkable(cell_id) {
				ctx.draw_rect_filled(
					int(cell_pos.x), int(cell_pos.y), app.grid_data.cell_size, app.grid_data.cell_size,
					gx.gray
				)
			}
			// draw cell ids
			ctx.draw_text(
				int(cell_pos.x) + app.grid_data.cell_size/2 - ctx.text_width(txt)/2, 
				int(cell_pos.y) + app.grid_data.cell_size/2 - ctx.text_height(txt)/2, 
				txt,
				gx.TextCfg{color: gx.white size: 12}
			)
		}
	}

	// draw grid lines
	for col in 0..app.grid_data.cols {
		x1 := col*app.grid_data.cell_size
		y1 := 0
		x2 := x1
		y2 := ctx.height
		ctx.draw_line(x1, y1, x2, y2, gx.green)
	}
	for row in 0..app.grid_data.rows {
		x1 := 0
		y1 := row*app.grid_data.cell_size
		x2 := ctx.width
		y2 := y1
		ctx.draw_line(x1, y1, x2, y2, gx.green)
	}

	// draw path
	pathsize := app.follower.path.len
	if pathsize == 0 {
		
	} else if pathsize >= 2 {
		for i in 0..pathsize - 1{
			pos1 := app.follower.path[i]
			pos2 := app.follower.path[i + 1]
			ctx.draw_line(pos1.x, pos1.y, pos2.x, pos2.y, gx.blue)
		}
	} else {

	}

	// draw path follower
	fl := app.follower
	ctx.draw_circle_filled(fl.pos.x, fl.pos.y, 8, gx.red)

	//draw debug text
	ctx.draw_text(0, 0, 'step: $fl.step/${fl.path.len - 1}/ t: $fl.t status: $fl.status', gx.TextCfg{color: gx.blue size: 24})
	ctx.end()
	app.follower.moving()
}

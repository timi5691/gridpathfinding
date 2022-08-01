module main

import gg
import gx
// import time
// import math
import rand
import rand.seed
import grid_path_finding as gpfd

const (
	txt_cfg1 = gx.TextCfg{color: gx.gray size: 16}
)

struct SelectArea {mut: x int y int w int h int}

struct App {
mut: 
	gg &gg.Context
	debug string

	grid_data gpfd.GridData
	half_cell_size int
	grid_test []int

	grid_random_size int = 7

	pathfollowers map[string]gpfd.PathFollower

	test_switch bool

	selecting bool
	select_area SelectArea
}

fn main() {
	mut app := &App{gg: 0}
	
	cell_size := 64
	width := 640
	height := 640

	app.grid_data = gpfd.create_grid_data(width/cell_size, height/cell_size, cell_size)
	app.half_cell_size = app.grid_data.cell_size/2

	app.gg = gg.new_context(
		bg_color: gx.black
		width: width
		height: height
		window_title: "TEST GRID PATH FINDING"

		init_fn: init
		frame_fn: frame
		click_fn: on_mouse_down
		unclick_fn: on_mouse_up
		keydown_fn: on_key_down

		user_data: app
	)

	app.gg.run()
}


fn init(mut app App){
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
	
	app.half_cell_size = app.grid_data.cell_size/2
	
	// grid test init
	app.grid_test = (go create_random_grid(app.grid_data.cols, app.grid_data.rows)).wait()

	app.grid_data.cells = (go create_cells_from_grid(app.grid_test, app.grid_data)).wait()

	mut walkables := (go app.grid_data.get_walkable_cells()).wait()
	for i in 0..10 {
		rn := rand.int_in_range(0, walkables.len) or {panic(err)}
		cell := walkables[rn]
		pos := app.grid_data.get_pixel_pos_center_cell_id(cell)
		flname := i.str()
		mut fl := app.grid_data.create_follower(flname, pos.x, pos.y)
		app.pathfollowers[flname] = fl
		walkables.delete(rn)
	}

	

}


fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app App) {
	click_at_cell := app.grid_data.get_id_from_pixel_pos(x, y)
	match button {
		.left {
			app.select_area.x = int(x)
			app.select_area.y = int(y)
			for _, mut fl in app.pathfollowers {
				fl_at_cell := app.grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
				if fl_at_cell != click_at_cell {
					fl.selected = false
				} else {
					fl.selected = true
				}
			}
			app.selecting = true
		}
		.right {
			for _, mut fl in app.pathfollowers {
				if fl.selected {
					if fl.status == 0 {
						fl_at_cell := app.grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
						pth := app.grid_data.path_finding(fl_at_cell, click_at_cell, true)
						fl.set_path(pth, mut app.grid_data)
						if fl.path.len > 1 {
							fl.start_move(fl.spd, mut app.grid_data)
						}
					} else {
						fl.change_point_to = click_at_cell
						fl.change_dir = true
					}
				}
			}
		}
		else {}
	}
}

fn on_mouse_up(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {
			// unclick_at_cell := app.grid_data.get_id_from_pixel_pos(x, y)
			sa := app.select_area
			for _, mut fl in app.pathfollowers {
				cond1 := if sa.w >= 0 {fl.pos.x >= sa.x && fl.pos.x <= sa.x + sa.w} else {fl.pos.x >= sa.x + sa.w && fl.pos.x <= sa.x}
				cond2 := if sa.h >= 0 {fl.pos.y >= sa.y && fl.pos.y <= sa.y + sa.h} else {fl.pos.y >= sa.y + sa.h && fl.pos.y <= sa.y}
				if cond1 && cond2 {
					fl.selected = true
				}
			}
			app.selecting = false
		}
		.right {
			
		}
		else {}
	}
}

fn on_key_down(key gg.KeyCode, m gg.Modifier, mut app App) {
	// app.debug = key.str()
	match key {
		.escape {
			app.gg.quit()
		}
		.o {
			app.test_switch = if app.test_switch {false} else {true}
		}
		.n {
			
		}
		else {}
	}
}

fn frame(mut app App) {
	ctx := app.gg
	ctx.begin()
	
	draw_grid(app.grid_data, app.grid_test, ctx)
	
	draw_followers(app.pathfollowers, ctx)

	draw_grid_info(app.grid_data, app.grid_test, ctx)
	draw_follower_info(app.pathfollowers, ctx)
	// draw selecting rectangle
	mut sa := &app.select_area
	sa.w = ctx.mouse_pos_x - sa.x
	sa.h = ctx.mouse_pos_y - sa.y
	draw_selecting_rectangle(app.selecting, sa, ctx)

	// draw debug text
	ctx.draw_text(0, 0, '$app.debug', gx.TextCfg{color: gx.blue size: 24})
	ctx.show_fps()
	ctx.end()

	// moving follower
	for _ , mut fl in app.pathfollowers {
		fl.moving(mut app.grid_data)
	}
}

fn create_random_grid(cols int, rows int) []int {
	mut grid := []int{}
	for _ in 0..cols*rows {
		n := rand.int_in_range(0, 5) or {panic(err)}
		if n <= 3 {
			grid << 0
		} else {
			grid << 1
		}
	}
	return grid
}

fn create_cells_from_grid (grid []int, grid_data gpfd.GridData) map[int]gpfd.GridCell {
	mut rs := map[int]gpfd.GridCell{}
	for i, v in grid {
		mut gc := gpfd.GridCell{}
		gc.pos = (go grid_data.cell_id_to_gridpos(i)).wait()
		gc.pixelpos = grid_data.gridpos_to_pixel_pos(gc.pos)
		gc.walkable = if v == 0 {true} else {false}
		rs[i] = gc
	}
	return rs
}

fn draw_grid(grid_data gpfd.GridData, grid_test []int, ctx gg.Context) {
	// half_cell_size := grid_data.cell_size/2
	for i in 0..grid_test.len {
		pos := grid_data.cells[i].pixelpos

		// draw walkable cells
		if grid_test[i] == 0 {
			ctx.draw_rect_filled(
				pos.x, pos.y, 
				grid_data.cell_size, grid_data.cell_size,
				gx.white
			)
		}

		// draw cell border
		ctx.draw_rect_empty(
			pos.x, pos.y, 
			grid_data.cell_size, grid_data.cell_size,
			gx.gray
		)

		
	}

	
}

fn draw_followers(followers map[string]gpfd.PathFollower, ctx gg.Context) {
	radius := 16
	for _, fl in followers {
		if fl.selected {
			ctx.draw_circle_empty(int(fl.pos.x), int(fl.pos.y), radius, gx.blue)
		}
		pos := fl.pos
		if fl.dir == 'right' {
			ctx.draw_triangle_filled(
				pos.x + radius/2, pos.y,
				pos.x - radius/2, pos.y - radius/2,
				pos.x - radius/2, pos.y + radius/2,
				fl.color
			)
		} else if fl.dir == 'left' {
			ctx.draw_triangle_filled(
				pos.x - radius/2, pos.y,
				pos.x + radius/2, pos.y - radius/2,
				pos.x + radius/2, pos.y + radius/2,
				fl.color
			)
		} else if fl.dir == 'up' {
			ctx.draw_triangle_filled(
				pos.x, pos.y - radius/2,
				pos.x - radius/2, pos.y + radius/2,
				pos.x + radius/2, pos.y + radius/2,
				fl.color
			)
		} else if fl.dir == 'down' {
			ctx.draw_triangle_filled(
				pos.x, pos.y + radius/2,
				pos.x - radius/2, pos.y - radius/2,
				pos.x + radius/2, pos.y - radius/2,
				fl.color
			)
		}
	}
}

fn draw_selecting_rectangle(selecting bool, sa SelectArea, ctx gg.Context) {
	if selecting {
		ctx.draw_rect_empty(sa.x, sa.y, sa.w, sa.h, gx.green)
	}
}

fn draw_grid_info(grid_data gpfd.GridData, grid_test []int, ctx gg.Context) {
	half_cell_size := grid_data.cell_size/2
	for i in 0..grid_test.len {
		pos := grid_data.cells[i].pixelpos
		// cell_id_txt := i.str()
		// is_cell_walkable := grid_data.is_cell_walkable(i)
		// txt := 'id: $cell_id_txt w: $is_cell_walkable'
		// txt := '$is_cell_walkable'
		txt := grid_data.cells[i].fl_future
		ctx.draw_text(
			int(pos.x) + half_cell_size - ctx.text_width(txt)/2, 
			int(pos.y) + half_cell_size - ctx.text_height(txt)/2,
			txt,
			gx.TextCfg{color: gx.purple, size: 16}
		)
	}
}

fn draw_follower_info(followers map[string]gpfd.PathFollower, ctx gg.Context) {
	for _, fl in followers {
		// txt := '$fl.reg_cell'
		txt := ''
		ctx.draw_text(
			int(fl.pos.x), int(fl.pos.y),
			txt,
			gx.TextCfg{color: gx.purple, size: 16}
		)
	}
}

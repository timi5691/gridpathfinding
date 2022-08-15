module main

import gg
import gx
// import time
// import math
import rand
import rand.seed
import grid_path_finding as gpfd
import camera2d

const (
	txt_cfg1 = gx.TextCfg{color: gx.gray size: 16}
)

struct SelectArea {
mut:
	x int y int w int h int selecting bool
	cam_click_x int cam_click_y int
}

struct App {
mut: 
	gg &gg.Context
	debug string

	grid_data gpfd.GridData
	half_cell_size int
	grid_test []int

	pathfollowers map[string]gpfd.PathFollower

	click_cell int

	select_area SelectArea

	// map[end_cell]map[cell]cost: cost to every walkable cells
	costs_data map[int]map[int]int
	final_regs map[int]map[string]bool
	cam2d camera2d.Camera2d
	
}

fn main() {
	mut app := &App{gg: 0}
	
	cell_size := 16
	width := 640
	height := 480

	app.grid_data = gpfd.create_grid_data(
		100,
		100,
		cell_size)
	app.half_cell_size = app.grid_data.cell_size/2

	app.cam2d.set_pos(0, 0)

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
	// create 100 followers
	for i in 0..200 {
		rn := rand.int_in_range(0, walkables.len) or {panic(err)}
		cell := walkables[rn]
		pos := app.grid_data.get_pixel_pos_center_cell_id(cell)
		flname := i.str()
		mut fl := app.grid_data.create_follower(flname, pos.x, pos.y)
		fl.spd = 0.1
		app.pathfollowers[flname] = fl
		walkables.delete(rn)
	}

}


fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app App) {
	cell_click := app.grid_data.get_id_from_pixel_pos(x + app.cam2d.x, y + app.cam2d.y)
	app.click_cell = cell_click
	match button {
		.left {
			app.select_area.x = int(x)
			app.select_area.y = int(y)
			app.select_area.cam_click_x = app.cam2d.x
			app.select_area.cam_click_y = app.cam2d.y
			app.select_area.selecting = true
			for _, mut fl in app.pathfollowers {
				fl_at_cell := app.grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
				if fl_at_cell != cell_click {
					fl.selected = false
				} else {
					fl.selected = true
				}
			}
		}
		.right {
			if _ := app.costs_data[cell_click] {} else {
				app.costs_data[cell_click] = app.grid_data.calc_cells_cost(cell_click)
			}
			gpfd.followers_set_final_cell(cell_click, mut app.pathfollowers, mut app.final_regs, mut app.costs_data)
		}
		else {}
	}
}



fn on_mouse_up(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {
			sa := app.select_area
			for _, mut fl in app.pathfollowers {
				cond1 := if sa.w >= 0 {fl.pos.x - app.cam2d.x >= sa.x && fl.pos.x - app.cam2d.x <= sa.x + sa.w} else {fl.pos.x - app.cam2d.x >= sa.x + sa.w && fl.pos.x - app.cam2d.x <= sa.x}
				cond2 := if sa.h >= 0 {fl.pos.y - app.cam2d.y >= sa.y && fl.pos.y - app.cam2d.y <= sa.y + sa.h} else {fl.pos.y - app.cam2d.y >= sa.y + sa.h && fl.pos.y - app.cam2d.y <= sa.y}
				if cond1 && cond2 {
					fl.selected = true
				}
			}
			app.select_area.selecting = false
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
			
		}
		.n {
			
		}
		.right {
			app.cam2d.x += 4
		}
		.left {
			app.cam2d.x -= 4
		}
		.up {
			app.cam2d.y -= 4
		}
		.down {
			app.cam2d.y += 4
		}
		else {}
	}
}

fn frame(mut app App) {
	ctx := app.gg
	ctx.begin()
	
	draw_grid(app.grid_data, app.grid_test, ctx, app.cam2d)
	draw_followers(app.pathfollowers, ctx, app.cam2d, app.grid_data)

	// draw selecting rectangle
	draw_selecting_rectangle(mut app.select_area, ctx, app.cam2d)
	// draw cost table example
	// if costs := app.costs_data[app.click_cell] {
	// 	for cell, cost in costs {
	// 		in_screen := is_cell_in_screen(cell, app.grid_data, app.cam2d, 640, 480)
	// 		if in_screen {
	// 			pos := app.grid_data.get_pixel_pos_center_cell_id(cell)
	// 			txt := cost.str()
	// 			drx := int(pos.x) - ctx.text_width(txt)/2 - app.cam2d.x
	// 			dry := int(pos.y) - ctx.text_height(txt)/2 - app.cam2d.y
	// 			ctx.draw_text(drx, dry, txt, gx.TextCfg{color: gx.gray size: 14})
	// 		} else {continue}
	// 	}
	// }

	// draw_grid_info(app.grid_data, app.grid_test, ctx, app.cam2d)
	
	// draw debug text
	// app.debug = ctx.mouse_pos_x.str()
	// ctx.draw_text(96, 0, '$app.debug', gx.TextCfg{color: gx.blue size: 24})
	ctx.show_fps()
	ctx.end()

	for _, mut fl in app.pathfollowers {
		if mut cost_table := app.costs_data[fl.final_cell] {
			fl.update_path(mut cost_table, app.grid_data)
		}
		fl.update_moving(mut app.costs_data[fl.cur_point], mut app.grid_data)
	}

	if ctx.mouse_pos_x >= 640 - app.grid_data.cell_size*2 {
		app.cam2d.x += 4
	} else if ctx.mouse_pos_x <= 0 + app.grid_data.cell_size*2 {
		app.cam2d.x -= 4
	}
	if ctx.mouse_pos_y >= 480 - app.grid_data.cell_size*2 {
		app.cam2d.y += 4
	} else if ctx.mouse_pos_y <= 0 + app.grid_data.cell_size*2 {
		app.cam2d.y -= 4
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

fn draw_grid(grid_data gpfd.GridData, grid_test []int, ctx gg.Context, cam2d camera2d.Camera2d) {
	// half_cell_size := grid_data.cell_size/2
	for i in 0..grid_test.len {
		in_screen := is_cell_in_screen(i, grid_data, cam2d, 640, 480)
		if !in_screen {
			continue
		}
		pos := grid_data.cells[i].pixelpos
		// draw walkable cells
		if grid_test[i] == 0 {
			ctx.draw_rect_filled(
				pos.x - cam2d.x, pos.y - cam2d.y, 
				grid_data.cell_size, grid_data.cell_size,
				gx.white
			)
		}

		// draw cell border
		// ctx.draw_rect_empty(
		// 	pos.x - cam2d.x, pos.y - cam2d.y, 
		// 	grid_data.cell_size, grid_data.cell_size,
		// 	gx.gray
		// )
	}
}

fn draw_selecting_rectangle(mut sa SelectArea, ctx gg.Context, cam2d camera2d.Camera2d) {
	if sa.selecting {
		if sa.cam_click_x != cam2d.x {
			sa.x += sa.cam_click_x - cam2d.x
			sa.cam_click_x = cam2d.x
		}
		if sa.cam_click_y != cam2d.y {
			sa.y += sa.cam_click_y - cam2d.y
			sa.cam_click_y = cam2d.y
		}
		sa.w = ctx.mouse_pos_x - sa.x
		sa.h = ctx.mouse_pos_y - sa.y
		ctx.draw_rect_empty(sa.x, sa.y, sa.w, sa.h, gx.blue)
	}
}

fn draw_followers(followers map[string]gpfd.PathFollower, ctx gg.Context, cam2d camera2d.Camera2d, grid_data gpfd.GridData) {
	radius := 16
	for _, fl in followers {
		in_screen := is_cell_in_screen(fl.cur_point, grid_data, cam2d, 640, 480)
		if !in_screen {
			continue
		}
		if fl.selected {
			ctx.draw_circle_empty(int(fl.pos.x) - cam2d.x, int(fl.pos.y) - cam2d.y, radius, gx.blue)
		}
		pos := gpfd.PixelPos{
			x: fl.pos.x - cam2d.x
			y: fl.pos.y - cam2d.y
		}

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

fn draw_grid_info(grid_data gpfd.GridData, grid_test []int, ctx gg.Context, cam2d camera2d.Camera2d) {
	half_cell_size := grid_data.cell_size/2
	for i in 0..grid_test.len {
		pos := gpfd.PixelPos {
			x: grid_data.cells[i].pixelpos.x
			y: grid_data.cells[i].pixelpos.y
		}
		mut txt := '${grid_data.cells[i].fl_name}'
		// txt = ''
		ctx.draw_text(
			int(pos.x) + half_cell_size - ctx.text_width(txt)/2, 
			int(pos.y) + half_cell_size - ctx.text_height(txt)/2,
			txt,
			gx.TextCfg{color: gx.purple, size: 16}
		)
	}
}


fn is_cell_in_screen(cell int, grid_data gpfd.GridData, cam2d camera2d.Camera2d, screen_width int, screen_height int) bool {
	cell_pos := grid_data.cells[cell].pixelpos
	real_cell_pos := gpfd.PixelPos{
		x: cell_pos.x - cam2d.x
		y: cell_pos.y - cam2d.y
	}
	
	xvalid := real_cell_pos.x + grid_data.cell_size >= 0 && real_cell_pos.x <= screen_width
	yvalid := real_cell_pos.y + grid_data.cell_size >= 0 && real_cell_pos.y <= screen_height
	
	return xvalid && yvalid
}

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
		click_fn: on_click
		keydown_fn: on_key_down

		user_data: app
	)

	app.gg.run()
}


fn init(mut app App){
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
	
	// random map with cell not walkable
	create_random_gridmap(mut app)

	app.half_cell_size = app.grid_data.cell_size/2
	
	
	app.pathfollowers['player'] = app.grid_data.create_follower('player', app.half_cell_size, app.half_cell_size)
	app.pathfollowers['player'].spd = 0.1

	for fl_name, mut fl in app.pathfollowers {
		if fl_name != 'player' {
			fl.start_move(fl.spd, mut app.grid_data)
		}
	}


}


fn on_click(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {
			click_id := app.grid_data.get_id_from_pixel_pos(x, y)

			plpos := app.pathfollowers['player'].pos
			plcellid := app.grid_data.get_id_from_pixel_pos(plpos.x, plpos.y)
			pth := app.grid_data.path_finding(plcellid, click_id, true)
			is_player_stopped := app.pathfollowers['player'].status == 0
			if is_player_stopped {
				app.pathfollowers['player'].set_path(pth, mut app.grid_data)
				app.pathfollowers['player'].start_move(app.pathfollowers['player'].spd, mut app.grid_data)
			} else {
				app.pathfollowers['player'].change_dir = true
				app.pathfollowers['player'].change_point_to = click_id
			}
		}
		.right {
			
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
			app.test_switch = if app.test_switch {false} else {true}
		}
		.n {
			// random map
			create_random_gridmap(mut app)
		}
		else {}
	}
}

fn frame(mut app App) {
	ctx := app.gg
	ctx.begin()
	
	half_cell_size := app.half_cell_size
	
	for i in 0..app.grid_test.len {
		pos := app.grid_data.cells[i].pixelpos
		if app.grid_test[i] == 0 {
			ctx.draw_rect_filled(
				pos.x, pos.y, 
				app.grid_data.cell_size, app.grid_data.cell_size,
				gx.white
			)
		}
		ctx.draw_rect_empty(
			pos.x, pos.y, 
			app.grid_data.cell_size, app.grid_data.cell_size,
			gx.gray
		)
	}

	// draw followers
	// radius := app.grid_data.cell_size/4
	radius := 16
	for flname , fl in app.pathfollowers {
		if flname == 'player' {
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
	

	// moving follower
	for fl_name , mut fl in app.pathfollowers {
		// update moving
		fl.moving(mut app.grid_data)

		// draw path
		// if fl_name != 'player' {
		// 	pth := fl.path
		// 	pathsize := pth.len

		// 	if pathsize >= 2 {
		// 		for i in 0..pathsize - 1{
		// 			pos1 := pth[i]
		// 			pos2 := pth[i + 1]
		// 			ctx.draw_line(pos1.x, pos1.y, pos2.x, pos2.y, gx.blue)
		// 		}
		// 	}
		// }

		// move to random walkable cell on map
		if fl_name != 'player' {
			if fl.status == 0 {
				walkable_cells := app.grid_data.get_walkable_cells()
				rn := rand.int_in_range(0, walkable_cells.len) or {panic(err)}
				cell_to := walkable_cells[rn]
				cur_id := app.grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
				newpth := app.grid_data.path_finding(cur_id, cell_to, true)
				fl.set_path(newpth, mut app.grid_data)
				fl.start_move(fl.spd, mut app.grid_data)
			}
		}
	}

	// draw player path
	plpth := app.pathfollowers['player'].path
	plpathsize := plpth.len

	if plpathsize >= 2 {
		for i in 0..plpathsize - 1{
			pos1 := plpth[i]
			pos2 := plpth[i + 1]
			ctx.draw_line(pos1.x, pos1.y, pos2.x, pos2.y, gx.red)
		}
	}

	// draw debug text
	ctx.draw_text(0, 0, '$app.debug', gx.TextCfg{color: gx.blue size: 24})
	ctx.show_fps()
	ctx.end()
}

fn create_random_gridmap (mut app App) {
	rd_size := app.grid_random_size
	for  _ , mut cell in app.grid_data.cells {
		n := rand.int_in_range(0, rd_size) or {panic(err)}
		if n == 0 {
			cell.walkable = false
			
		} else {
			cell.walkable = true
		}
	}
	app.grid_data.cells[0].walkable = true
	
	// test
	app.grid_test.clear()
	for i in 0..app.grid_data.cols*app.grid_data.rows {
		if app.grid_data.cells[i].walkable {
			app.grid_test << 0
		} else {
			app.grid_test << 1
		}
	}
}

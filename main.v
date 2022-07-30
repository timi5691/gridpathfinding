module main

import gg
import gx
// import time
// import math
import rand
import rand.seed
import grid_path_finding as gpfd

const (
	txt_cfg1 = gx.TextCfg{color: gx.gray size: 12}
)


struct App {
mut: 
	gg &gg.Context
	debug string

	grid_data gpfd.GridData
	half_cell_size int

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
		bg_color: gx.white
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
	// create_random_gridmap(mut app)

	app.half_cell_size = app.grid_data.cell_size/2
	
	
	app.pathfollowers['player'] = app.grid_data.create_follower('player', app.half_cell_size, app.half_cell_size)
	
	for i in 0..2 {
		if i == 0 {
			c := 0
			r := app.grid_data.rows/2
			x := app.grid_data.cell_size*c + app.half_cell_size
			y := app.grid_data.cell_size*r + app.half_cell_size
			id := app.grid_data.get_id_from_pixel_pos(x, y)
			id_to := id + (app.grid_data.cols - 1)
			app.pathfollowers['$i'] = app.grid_data.create_follower(
				'$i',
				x,
				y)
			pth := app.grid_data.path_finding(id, id_to, true)
			app.pathfollowers['$i'].set_path(pth, mut app.grid_data)
			app.pathfollowers['$i'].spd = 0.02
		} else if i == 1 {
			c := app.grid_data.cols - 1
			r := app.grid_data.rows/2
			x := app.grid_data.cell_size*c + app.half_cell_size
			y := app.grid_data.cell_size*r + app.half_cell_size
			id := app.grid_data.get_id_from_pixel_pos(x, y)
			id_to := id - (app.grid_data.cols - 1)
			app.pathfollowers['$i'] = app.grid_data.create_follower(
				'$i',
				app.grid_data.cell_size*c + app.half_cell_size,
				app.grid_data.cell_size*r + app.half_cell_size)
			pth := app.grid_data.path_finding(id, id_to, true)
			app.pathfollowers['$i'].set_path(pth, mut app.grid_data)
			app.pathfollowers['$i'].spd = 0.02
		}
	}
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
				app.pathfollowers['player'].start_move(0.05, mut app.grid_data)
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

	// draw not walkable_cells and cell_ids
	
	half_cell_size := app.half_cell_size
	
	for row in 0..app.grid_data.rows {
		for col in 0..app.grid_data.cols {
			gridpos := gpfd.GridPos{col: col row: row}
			cell_id := app.grid_data.gridpos_to_cell_id(gridpos)
			cell_pos := app.grid_data.gridpos_to_pixel_pos(gridpos)
			register := app.grid_data.cells[cell_id].register
			txt := '$cell_id/$register'
			// draw not walkable cells
			if !app.grid_data.is_cell_walkable(cell_id) {
				ctx.draw_rect_filled(
					int(cell_pos.x), int(cell_pos.y), app.grid_data.cell_size, app.grid_data.cell_size,
					gx.black
				)
			}
			// draw cell ids

			if app.test_switch {
				ctx.draw_text(
					int(cell_pos.x) + half_cell_size - ctx.text_width(txt)/2, 
					int(cell_pos.y) + half_cell_size - ctx.text_height(txt)/2, 
					txt,
					txt_cfg1
				)
			}
		}
	}

	// draw followers
	// radius := app.grid_data.cell_size/4
	radius := 8
	for _ , fl in app.pathfollowers {
		ctx.draw_circle_filled(int(fl.pos.x), int(fl.pos.y), radius, fl.color)
	}

	
	// draw debug text
	ctx.draw_text(0, 0, '$app.debug', gx.TextCfg{color: gx.blue size: 24})
	ctx.show_fps()
	ctx.end()

	// moving follower
	for fl_name , mut fl in app.pathfollowers {
		// update moving
		fl.moving(mut app.grid_data)

		// draw path
		
		pth := fl.path
		pathsize := pth.len

		if pathsize >= 2 {
			for i in 0..pathsize - 1{
				pos1 := pth[i]
				pos2 := pth[i + 1]
				ctx.draw_line(pos1.x, pos1.y, pos2.x, pos2.y, gx.blue)
			}
		}

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
}

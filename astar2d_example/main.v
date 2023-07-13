module main

import mohamedlt.vraylib as raylib
import astar2d
import rand
import rand.seed
import os
import benchmark

struct Game {
pub mut:
	test1         voidptr
	debug         string
	grid2d        astar2d.Grid2d
	x_table       map[int]f32
	y_table       map[int]f32
	texture_table map[int]raylib.Texture2D

	pos_path []astar2d.PixelPos

	pathfinding_cross     bool
	pathfinding_in_thread bool = true
	distance_optimize     bool = true
	// channel to hold result of x1y1_to_x2y2_get_path_to_channel function
	ch1 chan []astar2d.PixelPos
}

pub fn random_walkable(percent_walkable int, mut grid2d astar2d.Grid2d) {
	for i, _ in grid2d.cells {
		mut walkable := false
		walkable_number := rand.int_in_range(0, 100) or { panic(err) }

		if walkable_number <= percent_walkable {
			walkable = true
		}

		grid2d.cells[i].walkable = walkable
	}
}

fn ready(mut g Game) {
	rand.seed(seed.time_seed_array(2))

	g.grid2d = astar2d.create_grid2d(16.0, 40, 40)

	percent_walkable := 90
	random_walkable(percent_walkable, mut g.grid2d)

	player_id := 0
	player_gridpos := astar2d.GridPos{
		col: 5
		row: 6
	}
	g.x_table[player_id] = int(g.grid2d.cell_size * player_gridpos.col)
	g.y_table[player_id] = int(g.grid2d.cell_size * player_gridpos.row)
	player_cellid := g.grid2d.gridpos_to_id(player_gridpos)
	g.grid2d.set_cell_walkable(player_cellid, true)
	mut e0_texture_pth := os.resource_abs_path('assets/img/unit.png')
	g.texture_table[player_id] = raylib.load_texture(e0_texture_pth.str)
}

fn update(mut g Game) {
	pl_pos := astar2d.PixelPos{
		x: g.x_table[0]
		y: g.y_table[0]
	}
	// pl_cell := g.grid2d.pixelpos_to_id(pl_pos)

	// _on_left_mouse_button_pressed
	if raylib.is_mouse_button_pressed(0) {
		mpos := astar2d.PixelPos{f32(raylib.get_mouse_x()), f32(raylib.get_mouse_y())}
		mgridpos := g.grid2d.pixelpos_to_gridpos(mpos)
		mpos_center := g.grid2d.gridpos_to_pixelpos(mgridpos, false)
		g.x_table[0] = mpos_center.x
		g.y_table[0] = mpos_center.y

		// _on_right_mouse_button_pressed
	} else if raylib.is_mouse_button_pressed(1) {
		mpos := astar2d.PixelPos{f32(raylib.get_mouse_x()), f32(raylib.get_mouse_y())}

		if g.pathfinding_in_thread {
			spawn g.grid2d.x1y1_to_x2y2_get_path_to_channel(pl_pos.x, pl_pos.y,
				mpos.x, mpos.y, g.pathfinding_cross, g.distance_optimize,
				g.ch1)
		} else {
			mut b := benchmark.start()
			g.pos_path = g.grid2d.x1y1_to_x2y2_get_path(pl_pos.x, pl_pos.y,
				mpos.x, mpos.y, g.pathfinding_cross, g.distance_optimize)
			b.measure('get path time')
		}
	}

	// try to get path from g.ch1
	if g.pathfinding_in_thread {
		mut pth := []astar2d.PixelPos{}

		if g.ch1.try_pop(mut pth) == .success {
			g.pos_path = pth
		}
	}

	// switch between pathfinding in thread and pathfinding not in thread
	if raylib.is_key_pressed(raylib.key_home) {
		g.pathfinding_in_thread = !g.pathfinding_in_thread
	}

	// switch cross
	if raylib.is_key_pressed(raylib.key_end) {
		g.pathfinding_cross = !g.pathfinding_cross
	}

	// switch distance_optimize
	if raylib.is_key_pressed(raylib.key_delete) {
		g.distance_optimize = !g.distance_optimize
	}

	mut db := 'Pathfinding in thread: ${g.pathfinding_in_thread} (key home to change).\n'
	db = '${db}Cross: ${g.pathfinding_cross} (key end to change).\n'
	db = '${db}Distance optimize: ${g.distance_optimize} (key delete to change)'
	g.debug = db
}

fn draw(g Game) {
	raylib.begin_drawing()
	raylib.clear_background(raylib.black)

	// draw grid2d
	cell_size := int(g.grid2d.cell_size)

	for _, cell in g.grid2d.cells {
		if cell.walkable {
			raylib.draw_rectangle(int(cell.topleftpos.x), int(cell.topleftpos.y), cell_size,
				cell_size, raylib.white)
		} else {
			raylib.draw_rectangle(int(cell.topleftpos.x), int(cell.topleftpos.y), cell_size,
				cell_size, raylib.black)
		}
	}

	// draw entities
	for e, texture in g.texture_table {
		raylib.draw_texture_pro(texture, raylib.Rectangle{0, 0, 32, 32}, raylib.Rectangle{int(g.x_table[e]), int(g.y_table[e]), int(g.grid2d.cell_size), int(g.grid2d.cell_size)},
			raylib.Vector2{0, 0}, 0, raylib.green)
	}

	// draw path
	pth_len := g.pos_path.len

	if pth_len > 1 {
		for i in 0 .. pth_len - 1 {
			pos1 := g.pos_path[i]
			pos2 := g.pos_path[i + 1]
			raylib.draw_line(int(pos1.x), int(pos1.y), int(pos2.x), int(pos2.y), raylib.red)
		}
	}

	// draw debug
	raylib.draw_rectangle(0, 32, raylib.measure_text(g.debug.str, 18), 18 * 4,
		raylib.Color{0, 0, 0, 200})
	raylib.draw_text(g.debug.str, 0, 32, 18, raylib.white)

	// draw fps
	raylib.draw_f_p_s(0, 0)

	raylib.end_drawing()
}

fn main() {
	raylib.init_window(640, 640, 'test astar2d'.str)

	mut g := Game{}

	ready(mut g)

	raylib.set_target_f_p_s(60)

	for !raylib.window_should_close() {
		update(mut g)
		draw(g)
	}

	raylib.close_window()
}

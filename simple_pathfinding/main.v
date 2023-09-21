module main

import gg
import gx
import os
import rand
import rand.seed
import pathfinding

const (
	cols      = 20
	rows      = 20
	cell_size = 32
	w         = cols * cell_size
	h         = rows * cell_size
)

struct App {
mut:
	gg          &gg.Context
	imgs        []gg.Image
	grid2d_list []pathfinding.Grid2d

	debug      string
	mouse_pos  [2]f64
	cell_click int

	pathfinding_in_thread bool
	cross                 bool
	// dijkstra test variables
	ch_djmap   chan map[int]int
	djmap_test map[int]int
	djmover    pathfinding.DjmapMover
	// astar test variables
	ch_astar chan []pathfinding.PixelPos
	pf       pathfinding.PathFollow
}

fn (mut app App) create_image(img_pth string) !gg.Image {
	$if android {
		img := os.read_apk_asset(img_pth) or { panic(err) }
		return app.gg.create_image_from_byte_array(img)
	}

	return app.gg.create_image(os.resource_abs_path('assets/${img_pth}'))
}

fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app App) {
	pixelpos_click := pathfinding.PixelPos{x, y}
	gridpos_click := app.grid2d_list[0].pixelpos_to_gridpos(pixelpos_click)
	app.cell_click = app.grid2d_list[0].gridpos_to_id(gridpos_click)
	mouse_pos := pathfinding.PixelPos{pixelpos_click.x, pixelpos_click.y}

	match button {
		.left {
			app.djmover.cur_pos = mouse_pos
		}
		.right {
			if app.pathfinding_in_thread {
				spawn pathfinding.create_djmap(app.grid2d_list[0], gridpos_click, app.cross,
					app.ch_djmap)
			} else {
				app.djmap_test = (spawn app.grid2d_list[0].create_dijkstra_map(gridpos_click,
					app.cross)).wait()
				app.djmover.dest_cell = app.cell_click
			}

			destpos := app.grid2d_list[0].id_to_pixelpos(app.cell_click, false)
			distance_optimize := false
			if app.pathfinding_in_thread {
				spawn app.grid2d_list[0].x1y1_to_x2y2_get_path_to_channel(app.pf.cur_pos.x,
					app.pf.cur_pos.y, destpos.x, destpos.y, app.cross, distance_optimize,
					app.ch_astar)
			} else {
				app.pf.pth = (spawn app.grid2d_list[0].x1y1_to_x2y2_get_path(app.pf.cur_pos.x,
					app.pf.cur_pos.y, destpos.x, destpos.y, app.cross, distance_optimize)).wait()
				app.pf.dest_cell = app.cell_click
			}
		}
		else {}
	}
}

fn on_mouse_up(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {}
		.right {}
		else {}
	}
}

fn on_key_down(key gg.KeyCode, m gg.Modifier, mut app App) {
}

fn on_key_up(key gg.KeyCode, m gg.Modifier, mut app App) {
}

fn draw_djmap_cost(app App, px int, py int, cell pathfinding.Cell) {
	ctx := app.gg

	if app.djmap_test.len != 0 {
		cost := app.djmap_test[cell.id]
		ctx.draw_text(px + cell_size / 2 - ctx.text_width(cost.str()) / 2, py + cell_size / 2 - ctx.text_height(cost.str()) / 2,
			'${cost}', gx.TextCfg{
			color: gx.white
			size: 12
		})
	}
}

fn draw_grid(app App) {
	ctx := app.gg

	mut cl := gx.white
	cl.a = 50
	for col in 0 .. cols * 3 + 1 {
		x := col * cell_size
		ctx.draw_line(x, 0, x, h, cl)
	}
	for row in 0 .. rows * 3 + 1 {
		y := row * cell_size
		ctx.draw_line(0, y, w, y, cl)
	}
}

pub fn random_walkable(mut grid2d pathfinding.Grid2d) {
	for row in 0 .. grid2d.rows {
		for col in 0 .. grid2d.cols {
			gridpos := pathfinding.GridPos{row, col}
			id := grid2d.gridpos_to_id(gridpos)
			mut walkable := true
			walkable_number := rand.int_in_range(0, 100) or { panic(err) }

			if walkable_number > 95 {
				walkable = false
			}

			cell := pathfinding.Cell{
				id: id
				gridpos: gridpos
				walkable: walkable
			}
			grid2d.cells[id] = cell
		}
	}
}

fn init_images(mut app App) {
	img_dir_list := [
		'img/unit.png',
		'img/wall.png',
	]

	for i in 0 .. img_dir_list.len {
		img := app.create_image(img_dir_list[i]) or { panic(err) }
		app.imgs << img
	}
}

fn find_walkable_cells(app App) []pathfinding.Cell {
	mut walkable_cells := []pathfinding.Cell{}

	for _, cell in app.grid2d_list[0].cells {
		if cell.walkable {
			walkable_cells << cell
		}
	}

	return walkable_cells
}

fn randomize() {
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
}

fn main() {
	randomize()

	mut app := &App{
		gg: 0
	}

	app.gg = gg.new_context(
		bg_color: gx.black
		width: w
		height: h
		window_title: 'simple path finding'
		init_fn: init
		frame_fn: frame
		click_fn: on_mouse_down
		unclick_fn: on_mouse_up
		keydown_fn: on_key_down
		keyup_fn: on_key_up
		user_data: app
	)

	app.gg.run()
}

fn init(mut app App) {
	init_images(mut app)
	app.grid2d_list = []pathfinding.Grid2d{cap: 10 * 10}
	app.grid2d_list << pathfinding.Grid2d{}
	for mut grid2d in app.grid2d_list {
		grid2d.init_info(pathfinding.PixelPos{0 * cols * cell_size, 0 * rows * cell_size},
			cols, rows, cell_size)
		random_walkable(mut grid2d)
	}
	app.djmover.cur_pos = pathfinding.PixelPos{64, 64}
	app.pf.cur_pos = app.grid2d_list[0].id_to_pixelpos(56, true)
}

fn frame(mut app App) {
	ctx := app.gg
	update(mut app)
	ctx.begin()
	draw(mut app)
	ctx.end()
}

fn update(mut app App) {
	ctx := app.gg
	app.mouse_pos = [f64(ctx.mouse_pos_x), ctx.mouse_pos_y]!

	// try to get djmap, and player path from chanels
	if app.pathfinding_in_thread {
		mut rs := map[int]int{}
		if app.ch_djmap.try_pop(mut rs) == .success {
			app.djmap_test = rs.move()
			app.djmover.dest_cell = app.cell_click
		}

		mut rs2 := []pathfinding.PixelPos{}
		if app.ch_astar.try_pop(mut rs2) == .success {
			app.pf.pth = rs2
			app.pf.dest_cell = app.cell_click
		}
	}

	// code dijkstra pathfinding from app.pos_test to app.dest_cell
	app.djmover.moving_to_destination(app.grid2d_list[0], app.djmap_test, app.cross)

	// code astar pathfinding
	app.pf.follow_its_path(app.grid2d_list[0])

	// set debug text
	app.debug = 'hello world'
}

fn draw(mut app App) {
	ctx := app.gg

	draw_grid(app)

	for grid2d in app.grid2d_list {
		// draw_walls
		for _, cell in grid2d.cells {
			pos := grid2d.gridpos_to_pixelpos(cell.gridpos, false)
			px := int(pos.x)
			py := int(pos.y)
			if !cell.walkable {
				ctx.draw_rect_filled(px, py, f32(grid2d.cell_size), f32(grid2d.cell_size),
					gx.gray)
			}

			draw_djmap_cost(app, px, py, cell)
		}

		// draw grid2d border with red color
		ctx.draw_rect_empty(f32(grid2d.pxpos.x) + 1, f32(grid2d.pxpos.y) + 1, f32(grid2d.cell_size) * grid2d.cols - 1,
			f32(grid2d.cell_size) * grid2d.rows - 1, gx.red)

		// draw djmover pos (example: this is your character's position, and use for dijstra pathfinding test)
		ctx.draw_rect_empty(f32(app.djmover.cur_pos.x), f32(app.djmover.cur_pos.y), 32,
			32, gx.green)

		// draw pf pos (this pos is your character2's position, use for astar test)
		ctx.draw_circle_empty(f32(app.pf.cur_pos.x), f32(app.pf.cur_pos.y), cell_size / 2,
			gx.red)

		// draw pf pth
		if app.pf.pth.len > 0 {
			for pos in app.pf.pth {
				ctx.draw_circle_empty(f32(pos.x), f32(pos.y), 16, gx.yellow)
			}
		}

		// draw app.debug
		ctx.draw_text(10, 30, app.debug, gx.TextCfg{
			color: gx.green
		})

		// show fps
		ctx.show_fps()
	}
}

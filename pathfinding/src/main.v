module main

import gg
import gx
import os
import rand
import rand.seed
import mygrid2d
import myecount

struct RectSelectArea {
mut:
	pos     mygrid2d.PixelPos
	drawpos mygrid2d.PixelPos
	size    mygrid2d.PixelPos
	color   gx.Color = gx.green
	active  bool
}

struct App {
mut:
	gg     &gg.Context
	imgs   []gg.Image
	grid2d mygrid2d.Grid2d

	djmap_test map[int]int

	mover_world myecount.EWorld

	rectselectarea RectSelectArea
}

fn (app App) create_image(img_pth string) gg.Image {
	$if android {
		img := os.read_apk_asset(img_pth) or { panic(err) }
		return app.gg.create_image_from_byte_array(img)
	}
	return app.gg.create_image(os.resource_abs_path('assets/${img_pth}'))
}

fn main() {
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)

	mut app := &App{
		gg: 0
	}

	app.gg = gg.new_context(
		bg_color: gx.black
		width: 640
		height: 640
		window_title: 'grid path finding'
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

fn click_select_mover_team(mut mover mygrid2d.Mover, pixelpos_click mygrid2d.PixelPos, team int, app App) {
	if mover.team == 1 {
		if mygrid2d.myabs(int(pixelpos_click.x) - int(mover.current_pos.x)) <= int(app.grid2d.cell_size / 2)
			&& mygrid2d.myabs(int(pixelpos_click.y) - int(mover.current_pos.y)) <= int(app.grid2d.cell_size / 2) {
			mover.selected = true
		} else {
			mover.selected = false
		}
	}
}

fn rect_select_start(pixelpos_click mygrid2d.PixelPos, mut app App) {
	app.rectselectarea.pos = pixelpos_click
	app.rectselectarea.drawpos = pixelpos_click
	app.rectselectarea.active = true
}

fn rect_select_finished(mut app App) {
	app.rectselectarea.active = false
	app.rectselectarea.size = mygrid2d.PixelPos{0, 0}
}

fn select_movers_in_rect_select_area(mut app App) {
	for _, mut mover in app.grid2d.mover_map {
		if mover.team == 1 {
			in_rectselect_x := mover.current_pos.x >= app.rectselectarea.drawpos.x
				&& mover.current_pos.x <= app.rectselectarea.drawpos.x + app.rectselectarea.size.x
			in_rectselect_y := mover.current_pos.y >= app.rectselectarea.drawpos.y
				&& mover.current_pos.y <= app.rectselectarea.drawpos.y + app.rectselectarea.size.y
			if in_rectselect_x && in_rectselect_y {
				mover.selected = true
			}
		}
	}
}

fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app App) {
	pixelpos_click := mygrid2d.PixelPos{x, y}
	gridpos_click := app.grid2d.pixelpos_to_gridpos(pixelpos_click)
	cell_click := app.grid2d.gridpos_to_id(gridpos_click)
	match button {
		.left {
			for _, mut mover in app.grid2d.mover_map {
				team := 1
				click_select_mover_team(mut mover, pixelpos_click, team, app)
				rect_select_start(pixelpos_click, mut app)
			}
		}
		.right {
			for mover_id, mut mover in app.grid2d.mover_map {
				if mover.selected && mover.team == 1 {
					app.grid2d.create_dijkstra_map_for_mover(mover_id, x, y)
					app.grid2d.set_mover_target(mut mover, x, y)
				}
			}

			if _ := app.grid2d.djmaps[cell_click] {
				app.djmap_test = app.grid2d.djmaps[cell_click].clone()
			}
		}
		else {}
	}
}

fn on_mouse_up(x f32, y f32, button gg.MouseButton, mut app App) {
	match button {
		.left {
			select_movers_in_rect_select_area(mut app)
			rect_select_finished(mut app)
		}
		.right {}
		else {}
	}
}

fn on_key_down(key gg.KeyCode, m gg.Modifier, mut app App) {
}

fn on_key_up(key gg.KeyCode, m gg.Modifier, mut app App) {
}

pub fn (mut app App) grid2d_random_walkable() {
	for row in 0 .. app.grid2d.rows {
		for col in 0 .. app.grid2d.cols {
			gridpos := mygrid2d.GridPos{row, col}
			id := app.grid2d.gridpos_to_id(gridpos)
			mut walkable := true
			walkable_number := rand.int_in_range(0, 100) or { panic(err) }
			if walkable_number > 95 {
				walkable = false
			}
			cell := mygrid2d.Cell{
				id: id
				gridpos: gridpos
				walkable: walkable
			}
			app.grid2d.cells[id] = cell
		}
	}
}

pub fn (mut app App) create_movers() {
	mut walkable_cells := []mygrid2d.Cell{}
	for _, cell in app.grid2d.cells {
		if cell.walkable {
			walkable_cells << cell
		}
	}

	for _ in 0 .. 100 {
		n := rand.int_in_range(0, walkable_cells.len) or { panic(err) }
		new_mover_id := app.mover_world.new_entity()
		app.grid2d.mover_map[new_mover_id] = app.grid2d.create_mover(walkable_cells[n].gridpos)
		if new_mover_id < 5 {
			app.grid2d.mover_map[new_mover_id].team = 1
			app.grid2d.mover_map[new_mover_id].percent_speed = 0.1
		} else {
			app.grid2d.mover_map[new_mover_id].team = 0
		}
		walkable_cells.delete(n)
	}
}

fn init_images(mut app App) {
	img_dir_list := [
		'img/unit.png',
		'img/wall.png',
	]
	for i in 0 .. img_dir_list.len {
		img := app.create_image(img_dir_list[i])
		app.imgs << img
	}
}

fn init(mut app App) {
	init_images(mut app)

	app.grid2d.cell_size = 20
	app.grid2d.rows = 32
	app.grid2d.cols = 32
	app.grid2d.cross = true

	app.grid2d_random_walkable()

	app.create_movers()
}

fn (mut rectselectarea RectSelectArea) update_draw_pos_and_size(ctx gg.Context) {
	if rectselectarea.active {
		if ctx.mouse_pos_x >= rectselectarea.pos.x {
			rectselectarea.drawpos.x = rectselectarea.pos.x
			rectselectarea.size.x = ctx.mouse_pos_x - rectselectarea.pos.x
		} else {
			rectselectarea.drawpos.x = ctx.mouse_pos_x
			rectselectarea.size.x = rectselectarea.pos.x - ctx.mouse_pos_x
		}

		if ctx.mouse_pos_y >= rectselectarea.pos.y {
			rectselectarea.drawpos.y = rectselectarea.pos.y
			rectselectarea.size.y = ctx.mouse_pos_y - rectselectarea.pos.y
		} else {
			rectselectarea.drawpos.y = ctx.mouse_pos_y
			rectselectarea.size.y = rectselectarea.pos.y - ctx.mouse_pos_y
		}
	}
}

fn find_steps_to_stop_to_each_target(mut app App) {
	for target_id in app.grid2d.djmaps.keys() {
		app.grid2d.steps_to_stop[target_id] = app.grid2d.find_steps_to_stop(target_id,
			app.grid2d.cross)
	}
}

fn update_mover_rot_and_moving(mut app App) {
	for _, mut mover in app.grid2d.mover_map {
		// mover.debug = '${mover.visited_cells}'
		rot := mover.calc_mover_rot(app.grid2d)
		mover.rot = if rot != -1 { rot } else { mover.rot }
		mover.step_moving(app.grid2d.djmaps, mut app.grid2d)
	}
}

fn draw_debug_each_cell(app App, px int, py int, cell mygrid2d.Cell) {
	ctx := app.gg
	debug := cell.has_mover
	if debug {
		ctx.draw_text(px, py, '1', gx.TextCfg{ color: gx.red })
	} else {
		ctx.draw_text(px, py, '0', gx.TextCfg{ color: gx.red })
	}
}

fn draw_djmap_test_each_cell(app App, px int, py int, cell mygrid2d.Cell) {
	ctx := app.gg
	if app.djmap_test.len != 0 {
		ctx.draw_text(px, py, '${app.djmap_test[cell.id]}', gx.TextCfg{ color: gx.white, size: 12 })
	}
}

fn draw_grid_map(app App) {
	ctx := app.gg
	for _, cell in app.grid2d.cells {
		walkable := cell.walkable
		pos := app.grid2d.gridpos_to_pixelpos(cell.gridpos, false)
		px := int(pos.x)
		py := int(pos.y)
		if !walkable {
			ctx.draw_rect_filled(px, py, app.grid2d.cell_size, app.grid2d.cell_size, gx.gray)
		} else {
			ctx.draw_rect_filled(px, py, app.grid2d.cell_size, app.grid2d.cell_size, gx.white)
		}

		// draw_djmap_test_each_cell(app, px, py, cell)

		// draw_debug_each_cell(app, px, py, cell)
	}
}

fn draw_movers(mover_map map[int]mygrid2d.Mover, ctx gg.Context, imgs []gg.Image) {
	for _, mover in mover_map {
		x := mover.current_pos.x
		y := mover.current_pos.y
		rot := mover.rot
		mut cl := gx.blue
		if mover.team == 1 {
			cl = gx.green
		}
		if mover.selected {
			ctx.draw_image_with_config(gg.DrawImageConfig{
				flip_x: false
				flip_y: false
				img: &imgs[0]
				img_rect: gg.Rect{
					x: x - 8
					y: y - 8
					width: 16
					height: 16
				}
				part_rect: gg.Rect{
					x: 0
					y: 0
					width: 32
					height: 32
				}
				rotate: rot
				z: 0
				color: cl
			})
		} else {
			cl.a = 150
			ctx.draw_image_with_config(gg.DrawImageConfig{
				flip_x: false
				flip_y: false
				img: &imgs[0]
				img_rect: gg.Rect{
					x: x - 8
					y: y - 8
					width: 16
					height: 16
				}
				part_rect: gg.Rect{
					x: 0
					y: 0
					width: 32
					height: 32
				}
				rotate: rot
				z: 0
				color: cl
			})
		}

		ctx.draw_text(int(mover.current_pos.x), int(mover.current_pos.y), mover.debug,
			gx.TextCfg{ color: gx.red })
	}
}

fn draw_rect_select_area(app App) {
	ctx := app.gg
	if app.rectselectarea.active {
		ctx.draw_rect_empty(int(app.rectselectarea.drawpos.x), int(app.rectselectarea.drawpos.y),
			int(app.rectselectarea.size.x), int(app.rectselectarea.size.y), app.rectselectarea.color)
	}
}

fn frame(mut app App) {
	ctx := app.gg

	app.rectselectarea.update_draw_pos_and_size(ctx)
	find_steps_to_stop_to_each_target(mut app)
	update_mover_rot_and_moving(mut app)

	ctx.begin()
	draw_grid_map(app)
	draw_movers(app.grid2d.mover_map, ctx, app.imgs)
	draw_rect_select_area(app)
	ctx.draw_text(32, 32, '${app.grid2d.djmaps.len}', gx.TextCfg{ color: gx.white, size: 24 })
	ctx.end()
}

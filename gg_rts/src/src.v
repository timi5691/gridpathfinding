module src

import gg
import gx
import time
import os
import os.asset
import my_extra { Vec2, is_pos_in_rect, is_rect_in_rect }
import md_user_extra as uex
import md_itemlist { IconInfo, ItemInfo, ItemList, ItemListEvent }
import md_animated_sprite { ActionFrame, AnimatedSprite }
import md_grid { Grid }
import md_cam { Camera }
import md_select_area { SelectArea }
import md_gobj { Gobj }
import md_explosion { Explosion, new_explosion }
import md_sound_player { SoundPlayer }

/////////////////////////////////////////////////////////////////////////////////////
/// GAME

pub struct Game {
pub mut:
	ctx                    &gg.Context = unsafe { nil }
	img_map                map[string]&gg.Image
	icon_map               map[string]IconInfo
	delta                  f32
	left_mouse_down        bool
	left_mouse_pressed     bool
	click_count            int
	click_time             f32
	right_mouse_down       bool
	right_mouse_pressed    bool
	left_mouse_released    bool
	right_mouse_released   bool
	pressing_keys          [512]bool
	pressed_keys           [512]bool
	released_keys          [512]bool
	dt_sw                  time.StopWatch
	fps                    int
	game_gui_left_click_x  int
	game_gui_right_click_y int
	gui_click_pos          Vec2
	click_pos              Vec2
	right_gui_click_pos    Vec2
	right_click_pos        Vec2
	mouse_gui_pos          Vec2
	mouse_pos              Vec2
	ws                     gg.Size
	// user section
	debug                     string
	itlist                    ItemList
	cursor_aspr               AnimatedSprite
	grid                      Grid
	cam                       Camera
	select_area               SelectArea
	gobj_map                  map[int]Gobj
	cell_gobj_map             map[int]int
	nextcell_map              map[int]int
	test_dest_cell_id         int = -1
	in_cam_view_gobj_map      map[int]&Gobj
	explosions                []Explosion
	double_click_select_gteam int    = 1
	double_click_select_gtype string = 'soldier'
	double_click_selecting    bool
	worker1_working           bool = true
	visible_cells_map         map[int]bool
	sound_player_map          map[string]&SoundPlayer = {
		'laserShoot': &SoundPlayer{}
		'explosion':  &SoundPlayer{}
	}
}

struct SavWalkableMap {
	walkable_map map[int]bool
}

pub fn (game Game) is_double_left_click() bool {
	return game.left_mouse_pressed && game.click_count == 2
}

pub fn (game Game) is_key_pressed(k gg.KeyCode) bool {
	return game.pressed_keys[k]
}

pub fn (game Game) is_key_down(k gg.KeyCode) bool {
	return game.ctx.pressed_keys[k]
}

pub fn (game Game) is_key_released(k gg.KeyCode) bool {
	return game.released_keys[k]
}

pub fn save_data[T](data T, file_name string, base_dir string) {
	path := asset.get_path(base_dir, file_name)
	mut f := os.create(path) or { panic(err) }
	f.write_struct[T](data) or { panic(err) }
	f.close()
	println('write success')
}

pub fn load_data[T](file_name string, base_dir string) T {
	path := asset.get_path(base_dir, file_name)
	mut rs := T{}
	mut f := os.open(path) or {
		panic('error reading file ${path}')
		return rs
	}
	f.read_struct[T](mut rs) or { panic(err) }
	f.close()
	return rs
}

/////////////////////////////////////////////////////////////////////////////////////
// GAME INIT

pub fn load_assets(mut game Game) {
	items_img := game.ctx.create_image(asset.get_path('assets/imgs', 'items.png')) or { panic(err) }
	test_unit_img := game.ctx.create_image(asset.get_path('assets/imgs', 'test_unit.png')) or {
		panic(err)
	}
	cursors_img := game.ctx.create_image(asset.get_path('assets/imgs', 'cursors.png')) or {
		panic(err)
	}
	game.img_map = {
		'cursors':   &cursors_img
		'items':     &items_img
		'test_unit': &test_unit_img
	}
	game.icon_map = {
		'Potion':     IconInfo{
			img_name: 'items'
			tile_x:   1 * 16
			tile_y:   11 * 16
			tile_w:   16
			tile_h:   16
		}
		'Sword':      IconInfo{'items', 0 * 16, 13 * 16, 16, 16}
		'Bow':        IconInfo{'items', 8 * 16, 2 * 16, 16, 16}
		'Boots':      IconInfo{'items', 0 * 16, 0 * 16, 16, 16}
		'Book':       IconInfo{'items', 0 * 16, 4 * 16, 16, 16}
		'Flashlight': IconInfo{'items', 2 * 16, 13 * 16, 16, 16}
		'Scissors':   IconInfo{'items', 3 * 16, 11 * 16, 16, 16}
		'Yellow key': IconInfo{'items', 4 * 16, 9 * 16, 16, 16}
	}
}

pub fn ready(mut game Game) {
	for sp_name, _ in game.sound_player_map {
		if mut sp := game.sound_player_map[sp_name] {
			sp.init_engine()
		}
	}
	my_extra.randomize()
	game.ctx.set_bg_color(gx.black)

	// init grid
	game.grid = Grid{
		cols:      100
		rows:      100
		cell_size: 32.0
		cam_pos:   &game.cam.pos
	}
	game.grid.random_walkable_map(90)

	// test a simple item list
	game.itlist.gui_x = 32
	game.itlist.gui_y = 32
	game.itlist.width = 160
	game.itlist.height = 120
	game.itlist.item_info = {
		'Potion':     ItemInfo{
			name:   'Potion'
			amount: 10
		}
		'Sword':      ItemInfo{
			name:   'Sword'
			amount: 1
		}
		'Bow':        ItemInfo{
			name:   'Bow'
			amount: 1
		}
		'Boots':      ItemInfo{
			name:   'Boots'
			amount: 1
		}
		'Book':       ItemInfo{
			name:   'Book'
			amount: 1
		}
		'Flashlight': ItemInfo{
			name:   'Flashlight'
			amount: 1
		}
		'Scissors':   ItemInfo{
			name:   'Scissors'
			amount: 1
		}
		'Yellow key': ItemInfo{
			name:   'Yellow key'
			amount: 1
		}
	}
	game.itlist.active = false
	game.itlist.visible = false

	// init cursor animated sprite
	game.cursor_aspr = AnimatedSprite{
		pos:        Vec2{32 * 2 + 16, 32 * 2 + 16}
		offset:     Vec2{16, 16}
		action_map: {
			'free':     [
				ActionFrame{
					img_name: 'cursors'
					tile_x:   0 * 32
					tile_y:   3 * 32
					tile_w:   32
					tile_h:   32
				},
			]
			'not free': [
				ActionFrame{
					img_name: 'cursors'
					tile_x:   0 * 1
					tile_y:   3 * 5
					tile_w:   32
					tile_h:   32
				},
			]
		}
		action:     'free'
		fps:        10
	}
	game.cursor_aspr.scale = Vec2{2, 2}
	// game.cursor_aspr.color = gx.green
	game.cursor_aspr.start('free')
	game.cursor_aspr.size = Vec2{32, 32}

	// init select area
	game.select_area.cam_pos = &game.cam.pos

	// create random units
	number_of_moving_unit := 500
	game.gobj_map = uex.create_number_of_gobj_at_random_cell(number_of_moving_unit, game.grid).clone()
	for _, mut gobj in game.gobj_map {
		gobj.aspr.cam_pos = &game.cam.pos
	}
}

/////////////////////////////////////////////////////////////////////////////////////
// GAME MAIN LOOP

pub fn begin_process(mut game Game) {
	// test use item
	if game.is_key_pressed(.a) {
		if game.itlist.is_any_item_selected() {
			selected_item := game.itlist.selected_item
			game.itlist.use_item(selected_item, 1)
		}
	}

	// create steps map in thread (create data for path finding)
	if game.right_mouse_pressed {
		cross := true
		game.grid.create_steps_map_to_pos_in_thread(game.right_click_pos, cross)
		game.test_dest_cell_id = game.grid.pixelpos_to_id(game.right_click_pos)
	}

	// control select_area
	game.select_area.visible = false
	if game.left_mouse_down {
		game.select_area.visible = true
	}
	if game.left_mouse_down {
		game.select_area.calc_rect_info(game.click_pos, game.mouse_pos)
		game.select_area.calc_ren_info(game.click_pos, game.mouse_pos)
	}

	// double left click
	game.double_click_selecting = false
	if game.is_double_left_click() {
		cell_click := game.grid.pixelpos_to_id(game.click_pos)
		if gobj_id := game.cell_gobj_map[cell_click] {
			if gobj := game.gobj_map[gobj_id] {
				game.double_click_select_gteam = gobj.team
				game.double_click_select_gtype = gobj.gobj_type
				game.double_click_selecting = true
			}
		}
	}
}

pub fn process(mut game Game) {
	game.grid.update()

	game.cam.update(Vec2{game.grid.cols * game.grid.cell_size, game.grid.rows * game.grid.cell_size},
		game.mouse_gui_pos, game.delta)

	game.cursor_aspr.update(game.delta)
	game.cursor_aspr.pos = game.mouse_gui_pos

	game.itlist.ev = ItemListEvent{
		left_mouse_pressed:   game.left_mouse_pressed
		is_key_pressed_right: game.is_key_pressed(.right)
		is_key_pressed_left:  game.is_key_pressed(.left)
		is_key_pressed_down:  game.is_key_pressed(.down)
		is_key_pressed_up:    game.is_key_pressed(.up)
		mouse_click_gui_x:    game.gui_click_pos.x
		mouse_click_gui_y:    game.gui_click_pos.y
	}
	game.itlist.process()

	// update each unit
	game.visible_cells_map = map[int]bool{}
	for _, mut gobj in game.gobj_map {
		gobj.right_mouse_pressed = game.right_mouse_pressed
		gobj.right_mouse_released = game.right_mouse_released
		gobj.right_mouse_down = game.right_mouse_down
		gobj.left_mouse_pressed = game.left_mouse_pressed
		gobj.left_mouse_released = game.left_mouse_released
		gobj.left_mouse_down = game.left_mouse_down
		gobj.double_left_click = game.is_double_left_click()

		gobj.begin_moving(game.grid)

		if game.right_mouse_pressed {
			if gobj.player_selected {
				dest_pos := game.grid.pixelpos_to_cellcenterpos(game.mouse_pos)
				gobj.set_new_dest_pos(dest_pos)
			}
		}

		if _ := game.grid.steps_map[gobj.dest_cell] {
			gobj.moving_to_destination(game.grid, mut game.cell_gobj_map, mut game.nextcell_map,
				game.delta)
		} else {
			gobj.simple_moving_to_destination(game.grid, mut game.cell_gobj_map, mut game.nextcell_map,
				game.delta)
		}

		// animated sprite process
		gobj.aspr.pos = gobj.cur_pos
		gobj.aspr.cam_pos = &game.cam.pos
		gobj.control_aspr_rot(game.gobj_map)
		gobj.aspr.update(game.delta)

		// rotate sats for finding nearest enemy
		gobj.rotate_sat(game.delta)
		gobj.find_nearest_enemy(game.grid, game.cell_gobj_map, game.gobj_map)

		// update in camera view units
		if is_rect_in_rect(gobj.get_rect(), game.cam.rect) {
			unsafe {
				game.in_cam_view_gobj_map[gobj.id] = gobj
			}
			gobj.in_cam_view = true
		} else {
			if _ := game.in_cam_view_gobj_map[gobj.id] {
				game.in_cam_view_gobj_map.delete(gobj.id)
			}
			gobj.in_cam_view = false
		}
		uex.check_gobj_player_selected(mut gobj, game.left_mouse_pressed, game.left_mouse_released,
			game.select_area.rect, game.mouse_pos, game.grid.cell_size, game.double_click_selecting,
			game.double_click_select_gteam, game.double_click_select_gtype)

		// control attack timer and attack enemy
		gobj.control_attack_time(game.delta)
		atk_eid := gobj.get_attack_enemy_id(game.gobj_map)
		if atk_eid != -1 {
			gobj.attack_enemy(mut game.gobj_map)
			if gobj.in_cam_view {
				if mut sp := game.sound_player_map['laserShoot'] {
					go sp.play('assets/audio', 'laserShoot.wav')
				}
			}
			if e := game.gobj_map[atk_eid] {
				explosion := new_explosion(e.cur_pos.x, e.cur_pos.y, 8, 10, 2.0)
				game.explosions << explosion
			}
		}

		if gobj.is_hp_changed() && gobj.in_cam_view {
			if gobj.is_hp_zero() {
				if mut sp := game.sound_player_map['explosion'] {
					go sp.play('assets/audio', 'explosion.wav')
				}
			} else {
				if mut sp := game.sound_player_map['laserShoot'] {
					go sp.play('assets/audio', 'hitHurt.wav')
				}
			}
		}

		//
		gobj.check_is_hurt(game.delta)
		gobj.stop_moving_if_hp_zero(mut game.cell_gobj_map, mut game.nextcell_map)
		gobj.check_change_state(game.gobj_map)

		if gobj.team == 1 && gobj.hp > 0 && gobj.in_cam_view {
			can_see_cells := game.grid.get_cells_around_in_steps_except_visible_cells(gobj.cur_cell,
				gobj.steps_can_see, game.visible_cells_map)
			for cell in can_see_cells {
				if _ := game.visible_cells_map[cell] {
					continue
				}
				game.visible_cells_map[cell] = true
			}
		}
	}

	// update explosion effect
	for i, mut expl in game.explosions {
		expl.update(game.delta)
		if expl.finished {
			game.explosions.delete(i)
		}
	}
}

pub fn end_process(mut game Game) {
	if game.is_key_pressed(.escape) {
		game.ctx.quit()
	}
}

pub fn draw(mut game Game) {
	mut ctx := game.ctx

	// draw grid
	// game.grid.draw_self(game.ctx)
	game.grid.draw_visible_cell(game.ctx, game.visible_cells_map)

	// draw explosions
	for mut expl in game.explosions {
		if is_pos_in_rect(Vec2{expl.x, expl.y}, game.cam.rect) {
			expl.draw(mut ctx, game.cam.pos.x, game.cam.pos.y)
		}
	}

	// // draw test step map
	// uex.draw_test_steps_map(mut ctx, game.test_dest_cell_id, game.grid, game.cam.rect)

	// draw gobj
	mut in_cam_view_gobj_list := game.in_cam_view_gobj_map.values()
	mut in_cam_view_gobj_team_1 := []&Gobj{}
	in_cam_view_gobj_list.sort(a.cur_pos.y < b.cur_pos.y)

	for mut gobj in in_cam_view_gobj_list {
		if is_pos_in_rect(gobj.cur_pos, game.cam.rect) {
			if gobj.team == 1 {
				in_cam_view_gobj_team_1 << gobj
			}
			draw_pos := gobj.cur_pos.minus(game.cam.pos)
			mut self_cl := gx.blue
			if gobj.team == 2 {
				self_cl = gx.red
			}
			if gobj.hurt_time > -1 {
				self_cl = gx.white
			}
			if gobj.hp > 0 {
				if gobj.team == 1 {
					gobj.aspr.draw_self(mut ctx, game.img_map, self_cl)
				} else {
					if _ := game.visible_cells_map[gobj.cur_cell] {
						gobj.aspr.draw_self(mut ctx, game.img_map, self_cl)
					}
				}
			}
			if gobj.player_selected {
				ctx.draw_circle_empty(draw_pos.x, draw_pos.y, 16, gx.green)

				// test draw sats
				// gobj.draw_sats(mut ctx, game.cam.pos)

				// // draw line to nearest enemy id
				// if gobj.nearest_eid != -1 {
				// 	if e := game.gobj_map[gobj.nearest_eid] {
				// 		e_draw_pos := e.cur_pos.minus(game.cam.pos)
				// 		ctx.draw_line(draw_pos.x, draw_pos.y, e_draw_pos.x, e_draw_pos.y, gx.red)
				// 	}
				// }

				// // draw debug gobj
				// db := '${gobj.state}'
				// ctx.draw_text2(gg.DrawTextParams{
				// 	x:              int(draw_pos.x)
				// 	y:              int(draw_pos.y - 32)
				// 	text:           db
				// 	color:          gx.Color{255, 255, 255, 255}
				// 	align:          .center
				// 	vertical_align: .top
				// })

				// draw hp bar
				hp_cell := 5
				a := int(game.grid.cell_size / hp_cell)
				if gobj.hp > 0 {
					mut cl := if gobj.team == 1 { gx.green } else { gx.red }
					if gobj.is_hurt {
						cl = gx.white
					}
					cl.a = 255
					for i in 0 .. hp_cell {
						ctx.draw_rect_empty(draw_pos.x - game.grid.cell_size / 2.0 + i * a,
							draw_pos.y - game.grid.cell_size / 2.0 - 8, a, 8, gx.white)
					}
					ctx.draw_rect_filled(draw_pos.x - game.grid.cell_size / 2.0, draw_pos.y - game.grid.cell_size / 2.0 - 8,
						gobj.hp / gobj.max_hp * game.grid.cell_size, 8, cl)
					// ctx.draw_rect_empty(draw_pos.x  - game.grid.cell_size/2.0, draw_pos.y - game.grid.cell_size/2.0 - 8, 32.0, 8, gx.white)
				}
			}
		}
		gobj.hurt_end()
	}

	// draw select area
	game.select_area.draw_self(mut ctx)
}

pub fn draw_gui(mut game Game) {
	mut ctx := game.ctx
	wsize := gg.window_size()

	// draw debug
	ctx.draw_text2(gg.DrawTextParams{
		x:              wsize.width / 2
		y:              0
		text:           '${game.ws}'
		color:          gx.Color{255, 255, 255, 255}
		align:          .center
		vertical_align: .top
	})

	game.itlist.draw_items_with_icons(mut ctx, game.img_map, game.icon_map)

	// draw cursor
	game.cursor_aspr.draw_self(mut ctx, game.img_map, gx.green)

	//
	ctx.show_fps()
}

/////////////////////////////////////////////////////////////////////////////////////
// WORKER 1 PROCESS
pub fn worker1(mut game Game) {
	for game.worker1_working {
		// for _, gobj in game.gobj_map {

		// }
	}
}

/////////////////////////////////////////////////////////////////////////////////////
// GAME QUIT

pub fn quit(mut game Game) {
	for sp_name, _ in game.sound_player_map {
		if mut sp := game.sound_player_map[sp_name] {
			sp.uninit_engine()
		}
	}
	defer {
		game.ctx.quit()
	}
}

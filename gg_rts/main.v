module main

import gg
import time
import my_extra { Vec2, guipos_to_realpos }
import src {
	Game,
	begin_process,
	draw,
	draw_gui,
	end_process,
	load_assets,
	process,
	quit,
	ready,
}

#flag -D_SGL_DEFAULT_MAX_VERTICES=4194304
#flag -D_SGL_DEFAULT_MAX_COMMANDS=65536

/////////////////////////////////////////////////////////////////////////////////////
// MAIN FUNCTION
fn main() {
	mut game := &Game{}
	game.dt_sw = time.new_stopwatch()
	game.dt_sw.start()
	game.ctx = gg.new_context(
		window_title: 'gg grid rts demo'
		width:        640
		height:       480
		fullscreen:   false
		// fullscreen: true
		init_fn:    fn (mut game Game) {
			game.ws = game.ctx.window_size()
			spawn src.worker1(mut game)
		}
		event_fn:   fn (e &gg.Event, mut game Game) {
			match e.typ {
				.key_down {
					if game.pressing_keys[e.key_code] == false {
						game.pressing_keys[e.key_code] = true
						game.pressed_keys[e.key_code] = true
					}
				}
				.key_up {
					if game.pressing_keys[e.key_code] == true {
						game.pressing_keys[e.key_code] = false
						game.released_keys[e.key_code] = true
					}
				}
				.resized, .restored, .resumed {}
				.touches_began {}
				.touches_ended {}
				.mouse_down {}
				.mouse_up {}
				else {}
			}
		}
		click_fn:   fn (x f32, y f32, button gg.MouseButton, mut game Game) {
			if button == .left {
				game.left_mouse_down = true
				game.left_mouse_pressed = true
				game.click_count += 1
				game.gui_click_pos = Vec2{x, y}
				game.click_pos = guipos_to_realpos(game.gui_click_pos, game.cam.pos)
			} else if button == .right {
				game.right_mouse_down = true
				game.right_mouse_pressed = true
				game.right_gui_click_pos = Vec2{x, y}
				game.right_click_pos = guipos_to_realpos(game.right_gui_click_pos, game.cam.pos)
			}
		}
		unclick_fn: fn (x f32, y f32, button gg.MouseButton, mut game Game) {
			if button == .left {
				game.left_mouse_down = false
				game.left_mouse_released = true
			} else if button == .right {
				game.right_mouse_down = false
				game.right_mouse_released = true
			}
		}
		frame_fn:   fn (mut game Game) {
			game.dt_sw.restart()
			game.ctx.begin()
			game.mouse_gui_pos = Vec2{
				x: game.ctx.mouse_pos_x
				y: game.ctx.mouse_pos_y
			}
			game.mouse_pos = guipos_to_realpos(game.mouse_gui_pos, game.cam.pos)
			if game.click_count > 0 {
				game.click_time += game.delta
			}
			if game.click_time >= 0.5 {
				game.click_count = 0
				game.click_time = 0
			}
			begin_process(mut game)
			process(mut game)
			end_process(mut game)
			draw(mut game)
			draw_gui(mut game)
			game.ctx.end()
			end_frame(mut game)
		}
		resized_fn: fn (e &gg.Event, mut game Game) {
			game.ws = game.ctx.window_size()
		}
		quit_fn:    fn (e &gg.Event, mut game Game) {
			quit(mut game)
		}
		user_data:  game
	)

	load_assets(mut game)
	ready(mut game)
	game.ctx.run()
}

fn end_frame(mut game Game) {
	game.left_mouse_pressed = false
	game.right_mouse_pressed = false
	game.left_mouse_released = false
	game.right_mouse_released = false
	for i in 0 .. game.pressed_keys.len {
		game.pressed_keys[i] = false
	}
	for i in 0 .. game.released_keys.len {
		game.released_keys[i] = false
	}
	game.delta = f32(game.dt_sw.elapsed().seconds())
	game.fps = i32(1.0 / game.delta)
}

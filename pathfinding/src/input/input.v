module input

import mystructs
import gg
import grid2d
import astar2d
import dijkstra

pub fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app mystructs.App) {
	col := int(x/app.cell_size)
	row := int(y/app.cell_size)
	cell := row*app.cols + col
	match button {
		.left {
			if app.game_state == 0 {
				if app.grid[cell]['walkable'] == 1 {
					app.grid[cell]['walkable'] = 0
				} else {
					app.grid[cell]['walkable'] = 1
				}
			}
			
		}
		.right {
			app.entities[0]['xto'] = col*app.cell_size + app.half
			app.entities[0]['yto'] = row*app.cell_size + app.half
			e0cell := grid2d.xytocell(app.entities[0]['x'], app.entities[0]['y'], app)
			e0cellto := grid2d.xytocell(app.entities[0]['xto'], app.entities[0]['yto'], app)
			app.astar_paths[0] = astar2d.get_path(e0cell, e0cellto, app)
			app.dijkstra_maps[0] = dijkstra.create_dijkstra_map(e0cellto, app)
		}
		else {}
	}
}

pub fn on_mouse_up(x f32, y f32, button gg.MouseButton, mut app mystructs.App) {
	match button {
		.left {
			
		}
		.right {
			
		}
		else {}
	}
}

pub fn on_key_down(key gg.KeyCode, m gg.Modifier, mut app mystructs.App) {
	match key {
		.escape {
			app.gg.quit()
		}
		.o {
			
		}
		.n {
			
		}
		.right {
			
		}
		.left {
			
		}
		.up {
			
		}
		.down {
			
		}
		.t {
			
		}
		.c {
			if app.switches['is_cross'] {
				app.switches['is_cross'] = false
			} else {
				app.switches['is_cross'] = true
			}
		}
		else {}
	}
}
module input

import gg
import mystructs
import grid2d
import astar2d
import dijkstraforall as dijkstra

pub fn init(mut app mystructs.App) {
	app.grid = grid2d.create_grid_from_walkable_map(app.walkable_map)
	
	// find path using astar for one cell
	app.astar_path = astar2d.get_path(
		app.pos1['col'], app.pos1['row'], 
		app.pos2['col'], app.pos2['row'], 
		app.grid,
		app.is_cross, app.optimize
	)
	
	// find path for all cell using dijkstra
	app.dijkstra_map = dijkstra.create_dijkstra_map(
		app.pos2['col'], app.pos2['row'],
		app.grid,
		app.is_cross
	)
	app.debug = 'yellow line is astar path, green numbers is cost of a cell to destinate location calculated by dijkstra'
}

pub fn on_mouse_down(x f32, y f32, button gg.MouseButton, mut app mystructs.App) {
	col := int(x/app.cell_size)
	row := int(y/app.cell_size)
	cell := '$col $row'
	match button {
		.left {
			if _ := app.grid[cell] {
				app.grid[cell]['walkable'] = if app.grid[cell]['walkable'] == 1 {0} else {1}
			}
		}
		.right {
			app.pos2 = {'col': col, 'row': row}
			
			// find path using astar for one cell
			app.astar_path = astar2d.get_path(
				app.pos1['col'], app.pos1['row'], 
				app.pos2['col'], app.pos2['row'], 
				app.grid,
				app.is_cross, app.optimize
			)
			
			// find path for all cell using dijkstra
			app.dijkstra_map = dijkstra.create_dijkstra_map(
				app.pos2['col'], app.pos2['row'],
				app.grid,
				app.is_cross
			)
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
		else {}
	}
}

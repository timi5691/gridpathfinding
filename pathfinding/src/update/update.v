module update

import mystructs
import gx

pub fn frame(mut app mystructs.App) {
	draw(app)
}

pub fn draw(app mystructs.App) {
	ctx := app.gg
	ctx.begin()

	// draw grid map
	for cell in app.grid.keys() {
		col := app.grid[cell]['col']
		row := app.grid[cell]['row']
		walkable := app.grid[cell]['walkable']
		if walkable == 1 {
			ctx.draw_rect_filled(col*app.cell_size, row*app.cell_size, app.cell_size, app.cell_size, gx.gray)
		} else {
			ctx.draw_rect_filled(col*app.cell_size, row*app.cell_size, app.cell_size, app.cell_size, gx.black)
		}
	}

	// draw beginning location
	ctx.draw_rect_filled(app.pos1['col']*app.cell_size, app.pos1['row']*app.cell_size, app.cell_size, app.cell_size, gx.blue)

	// draw destination location
	ctx.draw_rect_filled(app.pos2['col']*app.cell_size, app.pos2['row']*app.cell_size, app.cell_size, app.cell_size, gx.red)
	
	half := app.cell_size/2
	
	// draw astar path
	if app.astar_path.len > 1 {
		for i in 0..app.astar_path.len - 1 {
			c1 := app.astar_path[i]
			c2 := app.astar_path[i + 1]
			x1 := app.grid[c1]['col']*app.cell_size + half
			y1 := app.grid[c1]['row']*app.cell_size + half
			x2 := app.grid[c2]['col']*app.cell_size + half
			y2 := app.grid[c2]['row']*app.cell_size + half
			ctx.draw_line(x1, y1, x2, y2, gx.yellow)
		}
	}

	// draw dijkstra map
	if app.dijkstra_map.len != 0 {
		for cell, cost in app.dijkstra_map {
			col := app.grid[cell]['col']
			row := app.grid[cell]['row']
			cost_txt := '$cost'
			ctx.draw_text(
				col*app.cell_size + half - ctx.text_width(cost_txt)/2,
				row*app.cell_size + half - ctx.text_height(cost_txt)/2,
				cost_txt,
				gx.TextCfg{color: gx.green size: 24}
			)
		}
	}

	// draw debug text
	ctx.draw_text(0, 0, app.debug, gx.TextCfg{color: gx.white size: 18})
	
	ctx.end()
}

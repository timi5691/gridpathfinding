module draw

import mystructs
import gx

pub fn draw(app mystructs.App) {
	ctx := app.gg
	ctx.begin()
	draw_grid(app)
	draw_e0_astar_path(app)
	draw_debug_text(app)
	ctx.end()
}

fn draw_debug_text(app mystructs.App) {
	ctx := app.gg
	ctx.draw_text(0, 0, app.debug, gx.TextCfg{size: 24 color: gx.blue})
	ctx.draw_text(0, 24, 'red line is astar path, blue number is cost calc by dijkstra')
	ctx.draw_text(0, 48, 'is_cross: ${app.switches['is_cross']}', gx.TextCfg{size: 24 color: gx.blue})
}

fn draw_grid(app mystructs.App) {
	ctx := app.gg
	for cell, cell_info in app.grid {
		if cell_info['walkable'] == 1 {
			ctx.draw_rect_filled(cell_info['x'], cell_info['y'], app.cell_size, app.cell_size, gx.white)
			ctx.draw_rect_empty(cell_info['x'], cell_info['y'], app.cell_size, app.cell_size, gx.green)
		} else {
			ctx.draw_rect_filled(cell_info['x'], cell_info['y'], app.cell_size, app.cell_size, gx.black)
		}
		if djmap := app.dijkstra_maps[0] {
			ctx.draw_text(cell_info['x'], cell_info['y'], '${djmap[cell]}', gx.TextCfg{size: 18 color: gx.rgba(0, 0, 255, 50)})
		}
	}
}

fn draw_e0_astar_path(app mystructs.App) {
	ctx := app.gg
	if pth := app.astar_paths[0] {
		for i in 0..pth.len - 1 {
			c1 := pth[i]
			c2 := pth[i+1]
			x1 := app.grid[c1]['xcenter']
			y1 := app.grid[c1]['ycenter']
			x2 := app.grid[c2]['xcenter']
			y2 := app.grid[c2]['ycenter']
			ctx.draw_line(x1, y1, x2, y2, gx.red)
		}
	}
}

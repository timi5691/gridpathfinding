module grid2d

import math { abs, sqrt }
import mystructs


pub fn create_grid(cols int, rows int, app mystructs.App) map[int]map[string]int {
	mut rs := map[int]map[string]int{}
	for col in 0..cols {
		for row in 0..rows {
			cell := row*cols + col
			rs[cell] = {
				'walkable': 1, 
				'col': col, 'row': row, 
				'x': col*app.cell_size, 'y': row*app.cell_size,
				'xcenter': col*app.cell_size + app.half, 'ycenter': row*app.cell_size + app.half,
			}
		}
	}
	return rs
}

pub fn create_grid_from_walkable_map(walkable_map [][]int, app mystructs.App) map[int]map[string]int {
	mut rs := map[int]map[string]int{}
	for i in 0..walkable_map.len {
		for j in 0..walkable_map[i].len {
			cell := i*app.cols + j
			rs[cell] = {'walkable': walkable_map[i][j], 'col': j, 'row': i}
		}
	}
	return rs
}

pub fn cell_get_center(cell int, app mystructs.App) map[string]int {
	return {
		'x': app.grid[cell]['xcenter'], 
		'y': app.grid[cell]['ycenter']
	}
}

pub fn cell_get_topleft(cell int, app mystructs.App) map[string]int {
	return {
		'x': app.grid[cell]['x'], 
		'y': app.grid[cell]['y']
	}
}

pub fn is_cell_exist(cell int, app mystructs.App) bool {
	if _ := app.grid[cell] {
		return true
	}
	return false
}

pub fn cell_get_neighbors(cell int, app mystructs.App) map[string]int {
	mut neighbors := map[string]int{}
	col := app.grid[cell]['col']
	row := app.grid[cell]['row']
	if !is_cell_exist(cell, app) {
		return neighbors
	}
	left_cond := col - 1 >= 0
	right_cond := col + 1 < app.cols
	up_cond := row - 1 >= 0
	down_cond := row + 1 < app.rows
	u := (row - 1)*app.cols + col
	d := (row + 1)*app.cols + col
	l := row*app.cols + col - 1
	r := row*app.cols + col + 1
	if left_cond {
		c := l
		if inf := app.grid[c] {
			if inf['walkable'] == 1 {
				neighbors['left'] = c
			}
		}
	}
	if right_cond {
		c := r
		if inf := app.grid[c] {
			if inf['walkable'] == 1 {
				neighbors['right'] = c
			}
		}
	}
	if up_cond {
		c := u
		if inf := app.grid[c] {
			if inf['walkable'] == 1 {
				neighbors['up'] = c
			}
		}
	}
	if down_cond {
		c := d
		if inf := app.grid[c] {
			if inf['walkable'] == 1 {
				neighbors['down'] = c
			}
		}
	}

	
	if app.switches['is_cross'] {
		if up_cond && left_cond {
			c := (row - 1)*app.cols + col - 1
			ex_cond := app.grid[u]['walkable'] == 1 && app.grid[l]['walkable'] == 1
			if inf := app.grid[c] {
				if inf['walkable'] == 1 && ex_cond {
					neighbors['upleft'] = c
				}
			}
		}
		if up_cond && right_cond {
			c := (row - 1)*app.cols + col + 1
			ex_cond := app.grid[u]['walkable'] == 1 && app.grid[r]['walkable'] == 1
			if inf := app.grid[c] {
				if inf['walkable'] == 1 && ex_cond {
					neighbors['upright'] = c
				}
			}
		}
		if down_cond && left_cond {
			c := (row + 1)*app.cols + col - 1
			ex_cond := app.grid[d]['walkable'] == 1 && app.grid[l]['walkable'] == 1
			if inf := app.grid[c] {
				if inf['walkable'] == 1 && ex_cond {
					neighbors['downleft'] = c
				}
			}
		}
		if down_cond && right_cond {
			c := (row + 1)*app.cols + col + 1
			ex_cond := app.grid[d]['walkable'] == 1 && app.grid[r]['walkable'] == 1
			if inf := app.grid[c] {
				if inf['walkable'] == 1 && ex_cond {
					neighbors['downright'] = c
				}
			}
		}
	}
	return neighbors
}

pub fn estimate_steps(cell1 int, cell2 int, app mystructs.App) int {
	return math.abs(app.grid[cell2]['col'] - app.grid[cell1]['col']) + math.abs(app.grid[cell2]['row'] - app.grid[cell1]['row'])
}

pub fn distance_two_cells(cell1 int, cell2 int, app mystructs.App) f64 {
	x1 := app.grid[cell1]['x']
	y1 := app.grid[cell1]['y']
	x2 := app.grid[cell2]['x']
	y2 := app.grid[cell2]['y']
	dx := abs(x2 - x1)
	dy := abs(y2 - y1)
	return sqrt(f64(dx*dx + dy*dy))
}

pub fn distance_two_point(x1 int, y1 int, x2 int, y2 int) f64 {
	dx := abs(x2 - x1)
	dy := abs(y2 - y1)
	return sqrt(f64(dx*dx + dy*dy))
}

pub fn xtocol(x int, app mystructs.App) int {
	return int(x/app.cell_size)
}

pub fn ytorow(y int, app mystructs.App) int {
	return int(y/app.cell_size)
}

pub fn xytocell(x int, y int, app mystructs.App) int {
	c := x/app.cell_size
	r := y/app.cell_size
	return r*app.cols + c
}
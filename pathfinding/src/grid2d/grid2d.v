module grid2d

import math { abs, sqrt }

pub fn create_grid(cols int, rows int) map[string]map[string]int {
	mut rs := map[string]map[string]int{}
	for col in 0..cols {
		for row in 0..rows {
			cell_pos := '$col $row'
			rs[cell_pos] = {'walkable': 1, 'col': col, 'row': row}
		}
	}
	return rs // {'col row': {'walkable': 0, 'col': col, 'row': row}}
}

pub fn create_grid_from_walkable_map(walkable_map [][]int) map[string]map[string]int {
	mut rs := map[string]map[string]int{}
	for i in 0..walkable_map.len {
		for j in 0..walkable_map[i].len {
			cell_pos := '$j $i'
			rs[cell_pos] = {'walkable': walkable_map[i][j], 'col': j, 'row': i}
		}
	}
	return rs
}

pub fn get_cell_info(col int, row int, grid map[string]map[string]int) map[string]int {
	cell := '$col $row'
	if _ := grid[cell] {
		return grid[cell]
	}
	return {'walkable': 0, 'col': -1, 'row': -1}
}

pub fn get_cellstr_info(cell string, grid map[string]map[string]int) map[string]int {
	if _ := grid[cell] {
		return grid[cell]
	}
	return {'walkable': 0, 'col': -1, 'row': -1}
}

pub fn cell_to_pos(col int, row int, cell_size int) map[string]int {
	return {'x': col*cell_size, 'y': row*cell_size}
}

pub fn is_cell_exist(col int, row int, grid map[string]map[string]int) bool {
	key := '$col $row'
	if _ := grid[key] {
		return true
	}
	return false
}

pub fn cell_get_neighbors(col int, row int, grid map[string]map[string]int, is_cross bool) map[string]string {
	mut neighbors := map[string]string{}
	if !is_cell_exist(col, row, grid) {
		return neighbors
	}
	if is_cross {
		neighbors = {
			'up': '$col ${row - 1}',
			'down': '$col ${row + 1}',
			'left': '${col - 1} $row',
			'right': '${col + 1} $row',
			'upleft': '${col - 1} ${row - 1}',
			'upright': '${col + 1} ${row - 1}',
			'downleft': '${col - 1} ${row + 1}',
			'downright': '${col + 1} ${row + 1}'
		}
	} else {
		neighbors = {
			'up': '$col ${row - 1}',
			'down': '$col ${row + 1}',
			'left': '${col - 1} $row',
			'right': '${col + 1} $row'
		}
	}
	if is_cross {}
	for i in neighbors.keys() {
		if cell_info := grid[neighbors[i]] {
			if walkable := cell_info['walkable'] {
				if walkable == 0 {
					neighbors.delete(i)
				} else {
					if i == 'downright' {
						if grid[neighbors['down']]['walkable'] != 1 || grid[neighbors['right']]['walkable'] != 1 {
							neighbors.delete(i)
						}
					} else if i == 'downleft' {
						if grid[neighbors['down']]['walkable'] != 1 || grid[neighbors['left']]['walkable'] != 1 {
							neighbors.delete(i)
						}
					} else if i == 'upright' {
						if grid[neighbors['up']]['walkable'] != 1 || grid[neighbors['right']]['walkable'] != 1 {
							neighbors.delete(i)
						}
					} else if i == 'upleft' {
						if grid[neighbors['up']]['walkable'] != 1 || grid[neighbors['left']]['walkable'] != 1 {
							neighbors.delete(i)
						}
					} else {
						continue
					}
				}
			}
		} else {
			neighbors.delete(i)
		}
	}
	return neighbors
}

pub fn estimate_steps(col1 int, row1 int, col2 int, row2 int) int {
	return math.abs(col2 - col1) + math.abs(row2 - row1)
}

pub fn calc_distance(col1 int, row1 int, col2 int, row2 int, cell_size int) f64 {
	pos1 := cell_to_pos(col1, row1, cell_size)
	pos2 := cell_to_pos(col2, row2, cell_size)
	x1 := pos1['x']
	y1 := pos1['y']
	x2 := pos2['x']
	y2 := pos2['y']
	dx := abs(x2 - x1)
	dy := abs(y2 - y1)
	return sqrt(f64(dx*dx + dy*dy))
}
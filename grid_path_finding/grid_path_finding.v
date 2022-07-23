module grid_path_finding

import math {sqrt}

pub struct GridData {
pub mut:
	cols int
	rows int
	cell_size int
	cells map[int]GridCell
}

pub struct GridPos {
pub mut:
	col int
	row int
}

pub struct PixelPos {
pub mut:
	x int
	y int
}

pub struct GridCell {
pub mut:
	pos GridPos
	pixelpos PixelPos
	walkable bool = true
}



struct Cost {
mut:
	to_start int
	to_end int
	total int
}

pub fn create_grid_data(cols int, rows int, cell_size int) GridData {
	mut grid_data := GridData {
		cols: cols
		rows: rows
		cell_size: cell_size
	}

	for col in 0..cols {
		for row in 0..rows {
			gridpos := GridPos{col: col row: row}
			pixelpos := PixelPos{x: col*grid_data.cell_size y: row*grid_data.cell_size}
			id := grid_data.gridpos_to_cell_id(gridpos)
			gridcell := GridCell{pos: gridpos pixelpos: pixelpos}
			grid_data.add_cell(id, gridcell)
		}
	}

	return grid_data
}

fn (mut data GridData) add_cell(cell_id int, cell GridCell) {
	data.cells[cell_id] = cell
}

pub fn (mut data GridData) set_cell_walkable(cell_id int, walkable bool) {
	if _ := data.cells[cell_id] {
		data.cells[cell_id].walkable = walkable
	}
}

pub fn (data GridData) is_cell_walkable(cell_id int) bool {
	if _ := data.cells[cell_id] {
		return data.cells[cell_id].walkable
	}
	return false
}

pub fn (data GridData) cell_id_to_gridpos(cell_id int) GridPos {
	r := cell_id/data.cols
	c := cell_id - r*data.cols
	return GridPos{col: c, row: r}
}

pub fn (data GridData) gridpos_to_cell_id(pos GridPos) int {
	return pos.row*data.cols + pos.col
}

pub fn (data GridData) get_id_from_pixel_pos(x int, y int) int {
	col := x/data.cell_size
	row := y/data.cell_size
	return row*data.cols + col
}

pub fn (data GridData) gridpos_to_pixel_pos(grid_pos GridPos) PixelPos {
	return PixelPos {
		x: grid_pos.col*data.cell_size
		y: grid_pos.row*data.cell_size
	}
}

fn (data GridData) get_neighbor_ids(cell_id int) []int {
	mut neighbor_ids := []int{}
	n_cells := data.cols*data.rows
	gridpos := data.cell_id_to_gridpos(cell_id)
	left := cell_id - 1
	right := cell_id + 1
	up := cell_id - data.cols
	down := cell_id + data.cols
	if left >= 0 && data.cell_id_to_gridpos(left).row == gridpos.row {
		if data.is_cell_walkable(left) {
		neighbor_ids << left}
	}
	if right < n_cells && data.cell_id_to_gridpos(right).row == gridpos.row {
		if data.is_cell_walkable(right) {
		neighbor_ids << right}
	}
	if up >= 0 && data.cell_id_to_gridpos(up).col == gridpos.col {
		if data.is_cell_walkable(up) {
		neighbor_ids << up}
	}
	if down < n_cells && data.cell_id_to_gridpos(down).col == gridpos.col {
		if data.is_cell_walkable(down) {
		neighbor_ids << down}
	}

	return neighbor_ids
}

fn myabs(a int) int {
	if a < 0 {
		return -a
	}
	return a
}

fn (data GridData) calc_cost(a int, b int, optimized bool) int {
	a_pos := data.cell_id_to_gridpos(a)
	b_pos := data.cell_id_to_gridpos(b)
	dy := myabs(b_pos.col - a_pos.col)
	dx := myabs(b_pos.row - a_pos.row)
	if optimized{
		return if dx == dy {2*dx} else {dx + dy}
	} else {
		return int(sqrt(dx*dx + dy*dy)) // if not optimized it will use sqrt func to calculate cost of cells
	}
}


fn find_best_cost(open map[int]Cost) int {
	mut result := -1
	for cell_id, costs in open {
		if result == -1 {
			result = cell_id
		} else {
			is_cost_total_smaller := costs.total < open[result].total
			is_cost_total_balance := costs.total == open[result].total
			is_cost_to_end_smaller := costs.to_end < open[result].to_end
			if is_cost_total_smaller || (is_cost_total_balance && is_cost_to_end_smaller) {
				result = cell_id
			}
		}
	}
	return result
}


fn calculate_path(current int, start int, parents map[int]int) []int {
	mut p := current
	mut path := []int{}
	for p != start {
		path.prepend(p)
		p = parents[p]
	}
	path.prepend(p)
	return path
}


fn (data GridData) remove_not_walkable_neighbor (mut neighbors []int) {
	for i in 0..neighbors.len {
		neighbor := neighbors[i]
		if !data.is_cell_walkable(neighbor) {
			neighbors.delete(i)
		}
	}
}

pub fn (data GridData) path_finding(start int, end int, optimized bool) []int {
	mut open := map[int]Cost{}
	mut closed := map[int]Cost{}
	mut parents := map[int]int{}
	
	dist_to_end := data.calc_cost(start, end, optimized)
	open[start] = Cost{
		to_start: 0
		to_end: dist_to_end
		total: dist_to_end
	}

	mut current := start
	mut path := []int{}

	for open.len != 0 {
		current = find_best_cost(open)
		if current == end {
			path = calculate_path(current, start, parents)
			return path
		}
		neighbors := data.get_neighbor_ids(current)
		for neighbor in neighbors {
			to_start_now := open[current].to_start + 1
			if _ := open[neighbor] {// replace (neighbor in to_research) for a little more performance
				if open[neighbor].to_start > to_start_now {
					open[neighbor].to_start = to_start_now
					open[neighbor].total = to_start_now + open[neighbor].to_end
					parents[neighbor] = current
				}
			} else if _ := closed[neighbor] {// replace (neighbor in closed) for a little more performance
				if closed[neighbor].to_start > to_start_now {
					closed[neighbor].to_start = to_start_now
					closed[neighbor].total = to_start_now + closed[neighbor].to_end
					parents[neighbor] = current
					open[neighbor] = closed[neighbor]
					closed.delete(neighbor)
				}
			} else {
				neighbor_to_end := data.calc_cost(neighbor, end, optimized)
				cost_n := Cost {
					to_start: to_start_now
					to_end: neighbor_to_end
					total: to_start_now + neighbor_to_end
				}
				open[neighbor] = cost_n
				parents[neighbor] = current
			}
		}
		closed[current] = open[current]
		open.delete(current)
	}
	if current != end{
		path = [start]
	}
	return path
}

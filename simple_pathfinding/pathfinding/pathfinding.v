module pathfinding

import math

pub struct GridPos {
pub mut:
	row int
	col int
}

pub struct PixelPos {
pub mut:
	x f64
	y f64
}

pub struct Cell {
pub mut:
	id       int
	gridpos  GridPos
	walkable bool
}

pub struct Grid2d {
pub mut:
	pxpos     PixelPos
	rows      int
	cols      int
	cell_size f64
	cells     map[int]Cell
}

pub fn (mut grid2d Grid2d) init_info(pos PixelPos, cols int, rows int, cell_size f64) {
	grid2d.pxpos = pos
	grid2d.cols = cols
	grid2d.rows = rows
	grid2d.cell_size = cell_size
}

pub fn (grid2d Grid2d) gridpos_to_id(gridpos GridPos) int {
	return gridpos.row * grid2d.cols + gridpos.col
}

pub fn (grid2d Grid2d) id_to_gridpos(id int) GridPos {
	r := id / grid2d.cols

	return GridPos{
		row: r
		col: id - r * grid2d.cols
	}
}

pub fn (grid2d Grid2d) gridpos_to_pixelpos(gridpos GridPos, center bool) PixelPos {
	if center {
		return PixelPos{
			x: gridpos.col * grid2d.cell_size + grid2d.cell_size / 2 + grid2d.pxpos.x
			y: gridpos.row * grid2d.cell_size + grid2d.cell_size / 2 + grid2d.pxpos.y
		}
	}

	return PixelPos{
		x: gridpos.col * grid2d.cell_size + grid2d.pxpos.x
		y: gridpos.row * grid2d.cell_size + grid2d.pxpos.y
	}
}

pub fn (grid2d Grid2d) pixelpos_to_gridpos(pp PixelPos) GridPos {
	return GridPos{
		row: int((pp.y - grid2d.pxpos.y) / grid2d.cell_size)
		col: int((pp.x - grid2d.pxpos.x) / grid2d.cell_size)
	}
}

pub fn (grid2d Grid2d) pixelpos_to_id(pp PixelPos) int {
	return grid2d.gridpos_to_id(grid2d.pixelpos_to_gridpos(pp))
}

pub fn (grid2d Grid2d) id_to_pixelpos(id int, center bool) PixelPos {
	return grid2d.gridpos_to_pixelpos(grid2d.id_to_gridpos(id), center)
}

pub fn (grid2d Grid2d) cell_get_neighbor_up(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1

	if nb_row < 0 {
		return cellpos
	}

	return GridPos{nb_row, cellpos.col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1

	if nb_row >= grid2d.rows {
		return cellpos
	}

	return GridPos{nb_row, cellpos.col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_left(cellpos GridPos) GridPos {
	nb_col := cellpos.col - 1

	if nb_col < 0 {
		return cellpos
	}

	return GridPos{cellpos.row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_right(cellpos GridPos) GridPos {
	nb_col := cellpos.col + 1

	if nb_col >= grid2d.cols {
		return cellpos
	}

	return GridPos{cellpos.row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_up_left(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col - 1

	if nb_col < 0 || nb_row < 0 {
		return cellpos
	}

	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_up_right(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col + 1

	if nb_col >= grid2d.cols || nb_row < 0 {
		return cellpos
	}

	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down_right(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col + 1

	if nb_col >= grid2d.cols || nb_row >= grid2d.rows {
		return cellpos
	}

	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down_left(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col - 1

	if nb_col < 0 || nb_row >= grid2d.rows {
		return cellpos
	}

	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_gridpos_neighbors(cellpos GridPos, cross bool) []GridPos {
	mut rs := []GridPos{}
	left := grid2d.cell_get_neighbor_left(cellpos)
	leftid := grid2d.gridpos_to_id(left)
	right := grid2d.cell_get_neighbor_right(cellpos)
	rightid := grid2d.gridpos_to_id(right)
	up := grid2d.cell_get_neighbor_up(cellpos)
	upid := grid2d.gridpos_to_id(up)
	down := grid2d.cell_get_neighbor_down(cellpos)
	downid := grid2d.gridpos_to_id(down)

	if left !in rs && left != cellpos && grid2d.cells[leftid].walkable {
		rs << left
	}

	if right !in rs && right != cellpos && grid2d.cells[rightid].walkable {
		rs << right
	}

	if up !in rs && up != cellpos && grid2d.cells[upid].walkable {
		rs << up
	}

	if down !in rs && down != cellpos && grid2d.cells[downid].walkable {
		rs << down
	}

	if !cross {
		return rs
	}

	up_left := grid2d.cell_get_neighbor_up_left(cellpos)
	upleftid := grid2d.gridpos_to_id(up_left)
	up_right := grid2d.cell_get_neighbor_up_right(cellpos)
	uprightid := grid2d.gridpos_to_id(up_right)
	down_left := grid2d.cell_get_neighbor_down_left(cellpos)
	downleftid := grid2d.gridpos_to_id(down_left)
	down_right := grid2d.cell_get_neighbor_down_right(cellpos)
	downrightid := grid2d.gridpos_to_id(down_right)

	if up_left !in rs && up_left != cellpos && grid2d.cells[upleftid].walkable && up in rs
		&& left in rs {
		rs << up_left
	}

	if up_right !in rs && up_right != cellpos && grid2d.cells[uprightid].walkable && up in rs
		&& right in rs {
		rs << up_right
	}

	if down_left !in rs && down_left != cellpos && grid2d.cells[downleftid].walkable && down in rs
		&& left in rs {
		rs << down_left
	}

	if down_right !in rs && down_right != cellpos && grid2d.cells[downrightid].walkable
		&& down in rs && right in rs {
		rs << down_right
	}

	return rs
}

pub fn (grid2d Grid2d) gridpos_neighbors_to_idpos_neighbors(gridpos_neighbors []GridPos) []int {
	mut id_neighbors := []int{}

	for gridpos in gridpos_neighbors {
		id_pos := grid2d.gridpos_to_id(gridpos)
		id_neighbors << id_pos
	}

	return id_neighbors
}

pub fn (grid2d Grid2d) cell_get_idpos_neighbors(cellpos GridPos, cross bool) []int {
	return grid2d.gridpos_neighbors_to_idpos_neighbors(grid2d.cell_get_gridpos_neighbors(cellpos,
		cross))
}

pub fn myabs(a int) int {
	if a < 0 {
		return -a
	}

	return a
}

pub fn calc_steps(gridpos1 GridPos, gridpos2 GridPos) int {
	return myabs(gridpos2.row - gridpos1.row) + myabs(gridpos2.col - gridpos1.col)
}

pub fn calc_steps2(gridpos1 GridPos, gridpos2 GridPos) f64 {
	dx := myabs(gridpos2.col - gridpos1.col)
	dy := myabs(gridpos2.row - gridpos1.row)
	return f64(math.sqrt(dx * dx + dy * dy))
}

pub fn (grid2d Grid2d) get_cells_around(cell_to int, cross bool) []int {
	if grid2d.cells[cell_to].walkable {
		return [cell_to]
	}

	mut costs := {
		cell_to: 0
	}
	mut opentable := [cell_to]
	mut step := 1

	for opentable.len != 0 {
		mut new_opentable := []int{}

		for cell in opentable {
			cell_pos := grid2d.id_to_gridpos(cell)
			neighbors := grid2d.cell_get_gridpos_neighbors(cell_pos, cross)
			mut is_stop := false

			for n in neighbors {
				id_n := grid2d.gridpos_to_id(n)

				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}

				if grid2d.cells[id_n].walkable {
					is_stop = true
				}
			}

			if is_stop {
				return new_opentable
			}
		}

		opentable = new_opentable.clone()
		step += 1
	}

	return []int{}
}

//

pub fn vec_length(vec PixelPos) f64 {
	return math.sqrt(vec.x * vec.x + vec.y * vec.y)
}

pub fn minus_two_vec(vec2 PixelPos, vec1 PixelPos) PixelPos {
	return PixelPos{vec2.x - vec1.x, vec2.y - vec1.y}
}

pub fn n_times_vec(n f64, vec PixelPos) PixelPos {
	return PixelPos{vec.x * n, vec.y * n}
}

pub fn vec_divide_n(vec PixelPos, n f64) PixelPos {
	return PixelPos{vec.x / n, vec.y / n}
}

pub fn plus_two_vec(vec1 PixelPos, vec2 PixelPos) PixelPos {
	return PixelPos{vec1.x + vec2.x, vec1.y + vec2.y}
}

pub fn normalize_vec(vec PixelPos) PixelPos {
	distance := vec_length(vec)
	return PixelPos{vec.x / distance, vec.y / distance}
}

// DIJKSTRA

pub fn (grid2d Grid2d) create_dijkstra_map(pos_to GridPos, cross bool) map[int]int {
	cell_to := grid2d.gridpos_to_id(pos_to)
	mut costs := {
		cell_to: 0
	}
	mut opentable := [cell_to]
	mut step := 1

	for opentable.len != 0 {
		mut new_opentable := []int{}

		for cell in opentable {
			cell_pos := grid2d.id_to_gridpos(cell)
			neighbors := grid2d.cell_get_gridpos_neighbors(cell_pos, cross)

			for n in neighbors {
				id_n := grid2d.gridpos_to_id(n)

				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}
			}
		}

		opentable = new_opentable.clone()
		step += 1
	}

	return costs
}

pub fn create_djmap(grid2d Grid2d, gridpos_click GridPos, cross bool, the_chanel chan map[int]int) {
	djmap := grid2d.create_dijkstra_map(gridpos_click, cross)
	the_chanel <- djmap
}

/// ASTAR

fn get_best_neighbor(open_neighbors_info map[int]map[string]f64) int {
	mut min_i := open_neighbors_info.keys()[0]
	mut min_f := open_neighbors_info[min_i]['steps_total']
	for i, _ in open_neighbors_info {
		f_i := open_neighbors_info[i]['steps_total']
		if f_i < min_f {
			min_i = i
			min_f = f_i
		}
	}

	return min_i
}

fn calculate_path(current_checking_cell int, start int, parents map[int]int) []int {
	mut path := []int{}
	mut p := current_checking_cell

	for p != start {
		// path << p
		path.prepend(p)
		p = parents[p]
	}

	// path << p
	path.prepend(p)

	return path
}

fn (grid2d Grid2d) calculate_path_pos(current_checking_cell int, start int, parents map[int]int) []PixelPos {
	mut path := []PixelPos{}
	mut p := current_checking_cell

	for p != start {
		// path << grid2d.id_to_pixelpos(p, true)
		path.prepend(grid2d.id_to_pixelpos(p, true))
		p = parents[p]
	}

	// path << grid2d.id_to_pixelpos(p, true)
	path.prepend(grid2d.id_to_pixelpos(p, true))

	return path
}

pub fn (grid2d Grid2d) cell1_to_cell2_get_path(cell_from int, cell_to int, cross bool, distance_optimize bool) []int {
	mut path := []int{}
	mut current_checking_cell := cell_from

	cellfrom_gridpos := grid2d.id_to_gridpos(cell_from)
	cellto_gridpos := grid2d.id_to_gridpos(cell_to)

	if cellfrom_gridpos.col < 0 || cellfrom_gridpos.col > grid2d.cols - 1
		|| cellfrom_gridpos.row < 0 || cellfrom_gridpos.row > grid2d.rows - 1 {
		return []
	}

	if cellto_gridpos.col < 0 || cellto_gridpos.col > grid2d.cols - 1 || cellto_gridpos.row < 0
		|| cellto_gridpos.row > grid2d.rows - 1 {
		return [cell_from]
	}

	steps_from_start_to_final := if !distance_optimize {
		f64(calc_steps(cellfrom_gridpos, cellto_gridpos))
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f64(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f64{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)
		if current_checking_cell == cell_to {
			path = calculate_path(current_checking_cell, cell_from, parents)
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_idpos_neighbors(current_gridpos, cross)

		for nb in neighbors {
			steps_to_neighbor := open_neighbors_info[current_checking_cell]['steps_to_cellfrom'] + 1
			if _ := open_neighbors_info[nb] {
				if open_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					open_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					open_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						open_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
				}
			} else if _ := closed_neighbors_info[nb] {
				if closed_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					closed_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					closed_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						closed_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
					open_neighbors_info[nb] = closed_neighbors_info[nb].clone()
					closed_neighbors_info.delete(nb)
				}
			} else {
				nb_gridpos := grid2d.id_to_gridpos(nb)
				nb_h := if !distance_optimize {
					f64(calc_steps(nb_gridpos, cellto_gridpos))
				} else {
					calc_steps2(nb_gridpos, cellto_gridpos)
				}
				open_neighbors_info[nb] = {
					'steps_to_cellfrom': steps_to_neighbor
					'steps_to_cellto':   nb_h
					'steps_total':       steps_to_neighbor + nb_h
				}
				parents[nb] = current_checking_cell
			}
		}

		closed_neighbors_info[current_checking_cell] = open_neighbors_info[current_checking_cell].clone()
		open_neighbors_info.delete(current_checking_cell)
	}

	if current_checking_cell != cell_to {
		path = [cell_from]
	}

	return path
}

pub fn (grid2d Grid2d) x1y1_to_x2y2_get_path(x1 f64, y1 f64, x2 f64, y2 f64, cross bool, distance_optimize bool) []PixelPos {
	mut path := []PixelPos{}

	cellfrom_gridpos := grid2d.pixelpos_to_gridpos(PixelPos{ x: x1, y: y1 })
	cellto_gridpos := grid2d.pixelpos_to_gridpos(PixelPos{ x: x2, y: y2 })
	cell_from := grid2d.pixelpos_to_id(PixelPos{ x: x1, y: y1 })
	cell_to := grid2d.pixelpos_to_id(PixelPos{ x: x2, y: y2 })
	mut current_checking_cell := cell_from

	if cellfrom_gridpos.col < 0 || cellfrom_gridpos.col > grid2d.cols - 1
		|| cellfrom_gridpos.row < 0 || cellfrom_gridpos.row > grid2d.rows - 1 {
		path = []
		return path
	}

	if cellto_gridpos.col < 0 || cellto_gridpos.col > grid2d.cols - 1 || cellto_gridpos.row < 0
		|| cellto_gridpos.row > grid2d.rows - 1 {
		[grid2d.id_to_pixelpos(cell_from, true)]
	}

	steps_from_start_to_final := if distance_optimize {
		f64(calc_steps(cellfrom_gridpos, cellto_gridpos))
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f64(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f64{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)

		if current_checking_cell == cell_to {
			path = grid2d.calculate_path_pos(current_checking_cell, cell_from, parents)
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_idpos_neighbors(current_gridpos, cross)

		for nb in neighbors {
			steps_to_neighbor := open_neighbors_info[current_checking_cell]['steps_to_cellfrom'] + 1

			if _ := open_neighbors_info[nb] {
				if open_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					open_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					open_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						open_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
				}
			} else if _ := closed_neighbors_info[nb] {
				if closed_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					closed_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					closed_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						closed_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
					open_neighbors_info[nb] = closed_neighbors_info[nb].clone()
					closed_neighbors_info.delete(nb)
				}
			} else {
				nb_gridpos := grid2d.id_to_gridpos(nb)
				nb_h := if distance_optimize {
					f64(calc_steps(nb_gridpos, cellto_gridpos))
				} else {
					calc_steps2(nb_gridpos, cellto_gridpos)
				}
				open_neighbors_info[nb] = {
					'steps_to_cellfrom': steps_to_neighbor
					'steps_to_cellto':   nb_h
					'steps_total':       steps_to_neighbor + nb_h
				}
				parents[nb] = current_checking_cell
			}
		}

		closed_neighbors_info[current_checking_cell] = open_neighbors_info[current_checking_cell].clone()
		open_neighbors_info.delete(current_checking_cell)
	}

	if current_checking_cell != cell_to {
		path = [grid2d.id_to_pixelpos(cell_from, true)]
	}

	return path
}

pub fn (grid2d Grid2d) x1y1_to_x2y2_get_path_to_channel(x1 f64, y1 f64, x2 f64, y2 f64, cross bool, distance_optimize bool, ch chan []PixelPos) []PixelPos {
	mut path := []PixelPos{}
	cellfrom_gridpos := grid2d.pixelpos_to_gridpos(PixelPos{ x: x1, y: y1 })
	cellto_gridpos := grid2d.pixelpos_to_gridpos(PixelPos{ x: x2, y: y2 })
	cell_from := grid2d.pixelpos_to_id(PixelPos{ x: x1, y: y1 })
	cell_to := grid2d.pixelpos_to_id(PixelPos{ x: x2, y: y2 })
	mut current_checking_cell := cell_from

	if cellfrom_gridpos.col < 0 || cellfrom_gridpos.col > grid2d.cols - 1
		|| cellfrom_gridpos.row < 0 || cellfrom_gridpos.row > grid2d.rows - 1 {
		path = []
		ch <- path
		return path
	}

	if cellto_gridpos.col < 0 || cellto_gridpos.col > grid2d.cols - 1 || cellto_gridpos.row < 0
		|| cellto_gridpos.row > grid2d.rows - 1 {
		[grid2d.id_to_pixelpos(cell_from, true)]
	}

	steps_from_start_to_final := if distance_optimize {
		f64(calc_steps(cellfrom_gridpos, cellto_gridpos))
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f64(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f64{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)

		if current_checking_cell == cell_to {
			path = grid2d.calculate_path_pos(current_checking_cell, cell_from, parents)
			ch <- path
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_idpos_neighbors(current_gridpos, cross)

		for nb in neighbors {
			steps_to_neighbor := open_neighbors_info[current_checking_cell]['steps_to_cellfrom'] + 1

			if _ := open_neighbors_info[nb] {
				if open_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					open_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					open_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						open_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
				}
			} else if _ := closed_neighbors_info[nb] {
				if closed_neighbors_info[nb]['steps_to_cellfrom'] > steps_to_neighbor {
					closed_neighbors_info[nb]['steps_to_cellfrom'] = steps_to_neighbor
					closed_neighbors_info[nb]['steps_total'] = steps_to_neighbor +
						closed_neighbors_info[nb]['steps_to_cellto']
					parents[nb] = current_checking_cell
					open_neighbors_info[nb] = closed_neighbors_info[nb].clone()
					closed_neighbors_info.delete(nb)
				}
			} else {
				nb_gridpos := grid2d.id_to_gridpos(nb)
				nb_h := if distance_optimize {
					f64(calc_steps(nb_gridpos, cellto_gridpos))
				} else {
					calc_steps2(nb_gridpos, cellto_gridpos)
				}
				open_neighbors_info[nb] = {
					'steps_to_cellfrom': steps_to_neighbor
					'steps_to_cellto':   nb_h
					'steps_total':       steps_to_neighbor + nb_h
				}
				parents[nb] = current_checking_cell
			}
		}

		closed_neighbors_info[current_checking_cell] = open_neighbors_info[current_checking_cell].clone()
		open_neighbors_info.delete(current_checking_cell)
	}

	if current_checking_cell != cell_to {
		path = [grid2d.id_to_pixelpos(cell_from, true)]
	}
	ch <- path
	return path
}

//

pub fn from_pos1_to_pos2_calc_new_pos(pos1 PixelPos, pos2 PixelPos, spd f64) PixelPos {
	move_dir := minus_two_vec(pos2, pos1)
	nor_move_dir := normalize_vec(move_dir)
	distance := vec_length(move_dir)
	if spd <= distance {
		return plus_two_vec(pos1, n_times_vec(spd, nor_move_dir))
	}
	return pos2
}

pub fn djmap_find_next_cell(djmap map[int]int, neighbors []int, cur_cell int) int {
	if djmap[cur_cell] == 0 {
		return cur_cell
	}
	if neighbors.len == 0 {
		return -1
	}
	mut rs := neighbors[0]
	mut min_cost := djmap[rs]
	for nei in neighbors {
		n_cost := djmap[nei]
		if n_cost < min_cost {
			rs = nei
			min_cost = n_cost
		}
	}
	return rs
}

pub struct PathFollow {
pub mut:
	cur_pos   PixelPos
	next_cell int = -1
	dest_cell int = -1
	spd       f64 = 1.0
	pth       []PixelPos
}

pub fn (mut pf PathFollow) follow_its_path(grid2d Grid2d) {
	cur_cell := grid2d.pixelpos_to_id(pf.cur_pos)
	if pf.dest_cell != -1 {
		// have destination
		if pf.pth.len > 0 {
			// pth not empty
			if pf.next_cell == -1 {
				// find next cell
				if cur_cell == pf.dest_cell {
					pf.dest_cell = -1
				} else {
					next_pos := pf.pth[0]
					pf.next_cell = grid2d.pixelpos_to_id(next_pos)
				}
			} else {
				// moving to next cell
				next_pos := pf.pth[0]
				if pf.cur_pos == next_pos {
					pf.next_cell = -1
					pf.pth.delete(0)
				} else {
					pf.cur_pos = from_pos1_to_pos2_calc_new_pos(pf.cur_pos, next_pos,
						pf.spd)
				}
			}
		}
	}
}

pub struct DjmapMover {
pub mut:
	cur_pos   PixelPos
	next_cell int = -1
	dest_cell int = -1
	spd       f64 = 4.0
}

pub fn (mut djmover DjmapMover) moving_to_destination(grid2d Grid2d, djmap map[int]int, cross bool) {
	if djmover.dest_cell != -1 {
		if djmap.keys().len != 0 {
			if djmover.next_cell == -1 {
				// find next cell
				cur_cell := grid2d.pixelpos_to_id(djmover.cur_pos)
				cur_gridpos := grid2d.pixelpos_to_gridpos(djmover.cur_pos)
				idpos_neighbors := grid2d.cell_get_idpos_neighbors(cur_gridpos, cross)
				next_cell := djmap_find_next_cell(djmap, idpos_neighbors, cur_cell)
				if next_cell != cur_cell {
					djmover.next_cell = next_cell
				} else {
					djmover.next_cell = -1
					djmover.dest_cell = -1
				}
			} else {
				// moving to next cell
				next_gridpos := grid2d.id_to_gridpos(djmover.next_cell)
				next_pxpos := grid2d.gridpos_to_pixelpos(next_gridpos, false)
				new_pos := from_pos1_to_pos2_calc_new_pos(djmover.cur_pos, next_pxpos,
					djmover.spd)
				djmover.cur_pos = new_pos
				if new_pos == next_pxpos {
					djmover.next_cell = -1
				}
			}
		}
	}
}

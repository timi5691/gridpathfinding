module astar2d

import math

pub struct GridPos {
pub mut:
	row int
	col int
}

pub struct PixelPos {
pub mut:
	x f32
	y f32
}

pub struct Cell {
pub mut:
	id         int
	walkable   bool
	gridpos    GridPos
	topleftpos PixelPos
	centerpos  PixelPos
}

pub struct Grid2d {
pub mut:
	cell_size f32
	rows      int
	cols      int
	cells     map[int]Cell
}

pub fn myabs(a int) int {
	if a < 0 {
		return -a
	}

	return a
}

pub fn create_grid2d(cell_size f32, cols int, rows int) Grid2d {
	mut grid2d := Grid2d{}
	grid2d.cell_size = cell_size
	grid2d.cols = cols
	grid2d.rows = rows
	number_of_cell := cols * rows

	for i in 0 .. number_of_cell {
		grid2d.cells[i] = Cell{
			id: i
			walkable: true
			gridpos: grid2d.id_to_gridpos(i)
			topleftpos: grid2d.id_to_pixelpos(i, false)
			centerpos: grid2d.id_to_pixelpos(i, true)
		}
	}

	return grid2d
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
			x: gridpos.col * grid2d.cell_size + grid2d.cell_size / 2
			y: gridpos.row * grid2d.cell_size + grid2d.cell_size / 2
		}
	}

	return PixelPos{
		x: gridpos.col * grid2d.cell_size
		y: gridpos.row * grid2d.cell_size
	}
}

pub fn (grid2d Grid2d) pixelpos_to_gridpos(pp PixelPos) GridPos {
	return GridPos{
		row: int(pp.y / grid2d.cell_size)
		col: int(pp.x / grid2d.cell_size)
	}
}

pub fn (grid2d Grid2d) pixelpos_to_id(pp PixelPos) int {
	return grid2d.gridpos_to_id(grid2d.pixelpos_to_gridpos(pp))
}

pub fn (grid2d Grid2d) id_to_pixelpos(id int, center bool) PixelPos {
	return grid2d.gridpos_to_pixelpos(grid2d.id_to_gridpos(id), center)
}

pub fn calc_steps(gridpos1 GridPos, gridpos2 GridPos) f32 {
	return f32(myabs(gridpos2.row - gridpos1.row) + myabs(gridpos2.col - gridpos1.col))
}

pub fn calc_steps2(gridpos1 GridPos, gridpos2 GridPos) f32 {
	dx := myabs(gridpos2.col - gridpos1.col)
	dy := myabs(gridpos2.row - gridpos1.row)
	return f32(math.sqrt(dx * dx + dy * dy))
}

pub fn (grid2d Grid2d) get_walkable_cells() []Cell {
	mut walkable_cells := []Cell{}

	for _, cell in grid2d.cells {
		if cell.walkable {
			walkable_cells << cell
		}
	}

	return walkable_cells
}

pub fn (grid2d Grid2d) is_cell_valid(cell_id int) bool {
	if _ := grid2d.cells[cell_id] {
		return true
	}

	return false
}

pub fn (grid2d Grid2d) is_pos_valid(posx f32, posy f32) bool {
	gridpos := grid2d.pixelpos_to_gridpos(PixelPos{posx, posy})
	return gridpos.col >= 0 && gridpos.col < grid2d.cols && gridpos.row >= 0
		&& gridpos.row < grid2d.rows
}

pub fn (mut grid2d Grid2d) set_cell_walkable(cell_id int, walkable bool) {
	if _ := grid2d.cells[cell_id] {
		grid2d.cells[cell_id].walkable = walkable
	}
}

pub fn (mut grid2d Grid2d) set_pos_walkable(posx f32, posy f32, walkable bool) {
	if grid2d.is_pos_valid(posx, posy) {
		cell_id := grid2d.pixelpos_to_id(PixelPos{posx, posy})
		grid2d.set_cell_walkable(cell_id, walkable)
	}
}

pub fn cell_get_neighbor_up(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	if nb_row < 0 {
		return cellpos
	}
	return GridPos{nb_row, cellpos.col}
}

pub fn cell_get_neighbor_down(cellpos GridPos, rows int) GridPos {
	nb_row := cellpos.row + 1
	if nb_row >= rows {
		return cellpos
	}
	return GridPos{nb_row, cellpos.col}
}

pub fn cell_get_neighbor_left(cellpos GridPos) GridPos {
	nb_col := cellpos.col - 1
	if nb_col < 0 {
		return cellpos
	}
	return GridPos{cellpos.row, nb_col}
}

pub fn cell_get_neighbor_right(cellpos GridPos, cols int) GridPos {
	nb_col := cellpos.col + 1
	if nb_col >= cols {
		return cellpos
	}
	return GridPos{cellpos.row, nb_col}
}

pub fn cell_get_neighbor_up_left(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col - 1
	if nb_col < 0 || nb_row < 0 {
		return cellpos
	}
	return GridPos{nb_row, nb_col}
}

pub fn cell_get_neighbor_up_right(cellpos GridPos, cols int) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col + 1
	if nb_col >= cols || nb_row < 0 {
		return cellpos
	}
	return GridPos{nb_row, nb_col}
}

pub fn cell_get_neighbor_down_right(cellpos GridPos, cols int, rows int) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col + 1
	if nb_col >= cols || nb_row >= rows {
		return cellpos
	}
	return GridPos{nb_row, nb_col}
}

pub fn cell_get_neighbor_down_left(cellpos GridPos, rows int) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col - 1
	if nb_col < 0 || nb_row >= rows {
		return cellpos
	}
	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbors(cellpos GridPos, cross bool) []int {
	mut rs := []int{}
	left := cell_get_neighbor_left(cellpos)
	leftid := grid2d.gridpos_to_id(left)
	right := cell_get_neighbor_right(cellpos, grid2d.cols)
	rightid := grid2d.gridpos_to_id(right)
	up := cell_get_neighbor_up(cellpos)
	upid := grid2d.gridpos_to_id(up)
	down := cell_get_neighbor_down(cellpos, grid2d.rows)
	downid := grid2d.gridpos_to_id(down)
	if leftid !in rs && left != cellpos && grid2d.cells[leftid].walkable {
		rs << leftid
		{
		}
	}

	if rightid !in rs && right != cellpos && grid2d.cells[rightid].walkable {
		rs << rightid
	}

	if upid !in rs && up != cellpos && grid2d.cells[upid].walkable {
		rs << upid
	}

	if downid !in rs && down != cellpos && grid2d.cells[downid].walkable {
		rs << downid
	}

	if !cross {
		return rs
	}

	up_left := cell_get_neighbor_up_left(cellpos)
	upleftid := grid2d.gridpos_to_id(up_left)
	up_right := cell_get_neighbor_up_right(cellpos, grid2d.cols)
	uprightid := grid2d.gridpos_to_id(up_right)
	down_left := cell_get_neighbor_down_left(cellpos, grid2d.rows)
	downleftid := grid2d.gridpos_to_id(down_left)
	down_right := cell_get_neighbor_down_right(cellpos, grid2d.cols, grid2d.rows)
	downrightid := grid2d.gridpos_to_id(down_right)

	if upleftid !in rs && up_left != cellpos && grid2d.cells[upleftid].walkable && upid in rs
		&& leftid in rs {
		rs << upleftid
	}

	if uprightid !in rs && up_right != cellpos && grid2d.cells[uprightid].walkable && upid in rs
		&& rightid in rs {
		rs << uprightid
	}

	if downleftid !in rs && down_left != cellpos && grid2d.cells[downleftid].walkable
		&& downid in rs && leftid in rs {
		rs << downleftid
	}

	if downrightid !in rs && down_right != cellpos && grid2d.cells[downrightid].walkable
		&& downid in rs && rightid in rs {
		rs << downrightid
	}

	return rs
}

fn get_best_neighbor(open_neighbors_info map[int]map[string]f32) int {
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
		path << p
		p = parents[p]
	}

	path << p

	return path
}

fn (grid2d Grid2d) calculate_path_pos(current_checking_cell int, start int, parents map[int]int) []PixelPos {
	mut path := []PixelPos{}
	mut p := current_checking_cell

	for p != start {
		path << grid2d.id_to_pixelpos(p, true)
		p = parents[p]
	}

	path << grid2d.id_to_pixelpos(p, true)

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
		calc_steps(cellfrom_gridpos, cellto_gridpos)
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f32(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f32{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)
		if current_checking_cell == cell_to {
			path = calculate_path(current_checking_cell, cell_from, parents)
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_neighbors(current_gridpos, cross)

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
					calc_steps(nb_gridpos, cellto_gridpos)
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

pub fn (grid2d Grid2d) x1y1_to_x2y2_get_path(x1 f32, y1 f32, x2 f32, y2 f32, cross bool, distance_optimize bool) []PixelPos {
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
		calc_steps(cellfrom_gridpos, cellto_gridpos)
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f32(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f32{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)

		if current_checking_cell == cell_to {
			path = grid2d.calculate_path_pos(current_checking_cell, cell_from, parents)
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_neighbors(current_gridpos, cross)

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
					calc_steps(nb_gridpos, cellto_gridpos)
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

pub fn (grid2d Grid2d) x1y1_to_x2y2_get_path_to_channel(x1 f32, y1 f32, x2 f32, y2 f32, cross bool, distance_optimize bool, ch chan []PixelPos) []PixelPos {
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
		calc_steps(cellfrom_gridpos, cellto_gridpos)
	} else {
		calc_steps2(cellfrom_gridpos, cellto_gridpos)
	}
	mut open_neighbors_info := {
		current_checking_cell: {
			'steps_to_cellfrom': f32(0)
			'steps_to_cellto':   steps_from_start_to_final
			'steps_total':       steps_from_start_to_final
		}
	}
	mut closed_neighbors_info := map[int]map[string]f32{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current_checking_cell = get_best_neighbor(open_neighbors_info)

		if current_checking_cell == cell_to {
			path = grid2d.calculate_path_pos(current_checking_cell, cell_from, parents)
			ch <- path
			return path
		}

		current_gridpos := grid2d.id_to_gridpos(current_checking_cell)
		neighbors := grid2d.cell_get_neighbors(current_gridpos, cross)

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
					calc_steps(nb_gridpos, cellto_gridpos)
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

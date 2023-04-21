module astar2d

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
	id             int
	walkable       bool
	gridpos        GridPos
}

pub struct Grid2d {
pub mut:
	cell_size     f32
	rows          int
	cols          int
	cells map[int]Cell
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
	number_of_cell := cols*rows
	for i in 0..number_of_cell {
		grid2d.cells[i] = Cell{
			id: i 
			walkable: true 
			gridpos: grid2d.id_to_gridpos(i)}

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

pub fn calc_steps(gridpos1 GridPos, gridpos2 GridPos) int {
	return myabs(gridpos2.row - gridpos1.row) + myabs(gridpos2.col - gridpos1.col)
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
		rs << leftid {
			
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
	if downleftid !in rs && down_left != cellpos && grid2d.cells[downleftid].walkable && downid in rs
		&& leftid in rs {
		rs << downleftid
	}
	if downrightid !in rs && down_right != cellpos && grid2d.cells[downrightid].walkable
		&& downid in rs && rightid in rs {
		rs << downrightid
	}
	return rs
}

fn get_best_neighbor(open_neighbors_info map[int]map[string]int) int {
	mut min_i := open_neighbors_info.keys()[0]
	mut min_f := open_neighbors_info[min_i]['f']
	for i, _ in open_neighbors_info {
		f_i := open_neighbors_info[i]['f']
		if f_i < min_f {
			min_i = i
			min_f = f_i
		}
	}
	return min_i
}

fn calculate_path(current int, start int, parents map[int]int) []int {
	mut path := []int{}
	mut p := current
	for p != start {
		// path.prepend(p)
		path << p
		p = parents[p]
	}
	// path.prepend(p)
	path << p
	return path
}

pub fn (grid2d Grid2d) get_path(cell int, cell2 int, cross bool) []int {
	mut path := []int{}
	start := cell
	mut current := cell

	cell_gridpos := grid2d.id_to_gridpos(cell)
	cell2_gridpos := grid2d.id_to_gridpos(cell2)
	steps_from_start_to_final := calc_steps(cell_gridpos, cell2_gridpos)
	mut open_neighbors_info := {current: {'g': 0, 'h': steps_from_start_to_final, 'f': steps_from_start_to_final}}
	mut closed_neighbors_info := map[int]map[string]int{}
	mut parents := map[int]int{}

	for open_neighbors_info.len != 0 {
		current = get_best_neighbor(open_neighbors_info)
		if current == cell2 {
			path = calculate_path(current, start, parents)
			return path
		}
		current_gridpos := grid2d.id_to_gridpos(current)
		neighbors := grid2d.cell_get_neighbors(current_gridpos, cross)
		for nb in neighbors {
			steps_to_neighbor := open_neighbors_info[current]['g'] + 1
			if _ := open_neighbors_info[nb] {
				if open_neighbors_info[nb]['g'] > steps_to_neighbor {
					open_neighbors_info[nb]['g'] = steps_to_neighbor
					open_neighbors_info[nb]['f'] = steps_to_neighbor + open_neighbors_info[nb]['h']
					parents[nb] = current
				}
			} else if _ := closed_neighbors_info[nb] {
				if closed_neighbors_info[nb]['g'] > steps_to_neighbor {
					closed_neighbors_info[nb]['g'] = steps_to_neighbor
					closed_neighbors_info[nb]['f'] = steps_to_neighbor + closed_neighbors_info[nb]['h']
					parents[nb] = current
					open_neighbors_info[nb] = closed_neighbors_info[nb].clone()
					closed_neighbors_info.delete(nb)
				}
			} else {
				nb_gridpos := grid2d.id_to_gridpos(nb)
				nb_h := calc_steps(nb_gridpos, cell2_gridpos)
				open_neighbors_info[nb] = {'g': steps_to_neighbor, 'h': nb_h, 'f': steps_to_neighbor + nb_h}
				parents[nb] = current
			}
		}
		closed_neighbors_info[current] = open_neighbors_info[current].clone()
		open_neighbors_info.delete(current)
	}
	if current != cell2{
		path = [cell]
	}
	return path
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


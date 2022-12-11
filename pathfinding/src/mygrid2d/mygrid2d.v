module mygrid2d

const (
	rotdata_dict = {
		'1 0':   0
		'1 -1':  45
		'0 -1':  90
		'-1 -1': 135
		'-1 0':  180
		'-1 1':  225
		'0 1':   270
		'1 1':   315
	}
)

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
	gridpos        GridPos
	walkable       bool
	has_mover      bool
	registered     bool
	register       int
	signal_giveway bool
}

pub struct Grid2d {
pub mut:
	rows          int
	cols          int
	cell_size     f32
	cross         bool = true
	cells         map[int]Cell
	steps_to_stop map[int]int
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

pub fn (grid2d Grid2d) cell_get_neighbor_up(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	if nb_row < 0 {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, cellpos.col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1
	if nb_row >= grid2d.rows {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, cellpos.col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_left(cellpos GridPos) GridPos {
	nb_col := cellpos.col - 1
	if nb_col < 0 {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{cellpos.row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_right(cellpos GridPos) GridPos {
	nb_col := cellpos.col + 1
	if nb_col >= grid2d.cols {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{cellpos.row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_up_left(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col - 1
	if nb_col < 0 || nb_row < 0 {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_up_right(cellpos GridPos) GridPos {
	nb_row := cellpos.row - 1
	nb_col := cellpos.col + 1
	if nb_col >= grid2d.cols || nb_row < 0 {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down_right(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col + 1
	if nb_col >= grid2d.cols || nb_row >= grid2d.rows {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbor_down_left(cellpos GridPos) GridPos {
	nb_row := cellpos.row + 1
	nb_col := cellpos.col - 1
	if nb_col < 0 || nb_row >= grid2d.rows {
		return GridPos{cellpos.row, cellpos.col}
	}
	return GridPos{nb_row, nb_col}
}

pub fn (grid2d Grid2d) cell_get_neighbors(cellpos GridPos, cross bool) []GridPos {
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

pub fn myabs(a int) int {
	if a < 0 {
		return -a
	}
	return a
}

pub fn calc_steps(gridpos1 GridPos, gridpos2 GridPos) int {
	return myabs(gridpos2.row - gridpos1.row) + myabs(gridpos2.col - gridpos1.col)
}

pub fn (grid2d Grid2d) get_cells_around(c int, _round int, round_limit int) []int {
	mut round := _round
	if round == 0 {
		if grid2d.cells[c].walkable && !grid2d.cells[c].has_mover {
			return [c]
		} else {
			round += 1
		}
	}
	mut rs := []int{}
	mut times := round
	cols := grid2d.cols
	c_grid_pos := grid2d.id_to_gridpos(c)
	for rs.len == 0 && times <= round_limit {
		rs = []int{}
		up_start := c - times * cols - times
		mut up_edge := []int{}
		for i in 0 .. 2 * times {
			a := up_start + i
			up_edge << a
			a_grid_pos := grid2d.id_to_gridpos(a)
			cond1 := c_grid_pos.row - a_grid_pos.row == times
			cond2 := a_grid_pos.row >= 0 && a_grid_pos.row < grid2d.rows
			cond3 := a_grid_pos.col >= 0 && a_grid_pos.col < cols
			cond4 := grid2d.cells[a].walkable && !grid2d.cells[a].has_mover
			if cond1 && cond2 && cond3 && cond4 {
				rs << a
			}
		}

		right_start := up_edge.last() + 1
		mut right_edge := []int{}
		for i in 0 .. 2 * times {
			a := right_start + i * cols
			right_edge << a
			a_grid_pos := grid2d.id_to_gridpos(a)
			cond1 := a_grid_pos.col - c_grid_pos.col == times
			cond2 := a_grid_pos.col < grid2d.cols && a_grid_pos.col >= 0
			cond3 := a_grid_pos.row >= 0 && a_grid_pos.row < grid2d.rows
			cond4 := grid2d.cells[a].walkable && !grid2d.cells[a].has_mover
			if cond1 && cond2 && cond3 && cond4 {
				rs << a
			}
		}

		down_start := right_edge.last() + cols
		mut down_edge := []int{}
		for i in 0 .. 2 * times {
			a := down_start - i
			down_edge << a
			a_grid_pos := grid2d.id_to_gridpos(a)
			cond1 := a_grid_pos.row - c_grid_pos.row == times
			cond2 := a_grid_pos.row < grid2d.rows && a_grid_pos.row >= 0
			cond3 := a_grid_pos.col >= 0 && a_grid_pos.col < cols
			cond4 := grid2d.cells[a].walkable && !grid2d.cells[a].has_mover
			if cond1 && cond2 && cond3 && cond4 {
				rs << a
			}
		}

		left_start := down_edge.last() - 1
		mut left_edge := []int{}
		for i in 0 .. 2 * times {
			a := left_start - i * cols
			left_edge << a
			a_grid_pos := grid2d.id_to_gridpos(a)
			cond1 := c_grid_pos.col - a_grid_pos.col == times
			cond2 := a_grid_pos.col >= 0 && a_grid_pos.col < cols
			cond3 := a_grid_pos.row >= 0 && a_grid_pos.row < grid2d.rows
			cond4 := grid2d.cells[a].walkable && !grid2d.cells[a].has_mover
			if cond1 && cond2 && cond3 && cond4 {
				rs << a
			}
		}

		if rs.len != 0 {
			return rs
		}

		times += 1
	}

	return rs
}

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
			neighbors := grid2d.cell_get_neighbors(cell_pos, cross)
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

/////////////////////////////////////////////////////////////////////////////

pub struct Mover {
pub mut:
	id             int
	start_pos      PixelPos
	current_pos    PixelPos
	grid_pos       GridPos
	id_pos         int
	old_id_pos     int
	next_pos       PixelPos
	target_pos     PixelPos
	target_gridpos GridPos
	percent_moved  f32 = 1.0
	percent_speed  f32 = 0.1
	cost_to_stop   int
	visited_cells  []int
	selected       bool
	costdata_id    int = -1
	rot            int
	debug          string
}

pub struct CellCost {
pub mut:
	cell_id    int
	cost       int
	steps      int
	has_mover  bool
	registered bool
}

pub fn (grid2d Grid2d) create_mover(gridpos GridPos) Mover {
	pixelpos := grid2d.gridpos_to_pixelpos(gridpos, true)
	id_pos := grid2d.pixelpos_to_id(pixelpos)
	grid_pos := grid2d.id_to_gridpos(id_pos)
	return Mover{
		start_pos: pixelpos
		current_pos: pixelpos
		grid_pos: grid_pos
		next_pos: pixelpos
		target_pos: pixelpos
		target_gridpos: grid_pos
		id_pos: id_pos
		old_id_pos: id_pos
	}
}

fn (mut mover Mover) on_leave_cell(mut grid2d Grid2d) {
	if mover.old_id_pos != mover.id_pos {
		grid2d.cells[mover.old_id_pos].has_mover = false
		mover.old_id_pos = mover.id_pos
	}
}

pub fn (mover Mover) is_step_reached() bool {
	return mover.current_pos == mover.next_pos
}

pub fn (mover Mover) unreg(current_cell int, mut grid2d Grid2d) {
	if grid2d.cells[current_cell].register == mover.id {
		grid2d.cells[current_cell].registered = false
	}
}

pub fn (mover Mover) is_target_reached() bool {
	return mover.target_gridpos == mover.grid_pos
}

fn (mut mover Mover) find_neighbors(costdata map[int]int, grid2d Grid2d, cross bool) []CellCost {
	gridpos_neighbors := grid2d.cell_get_neighbors(mover.grid_pos, cross)
	id_neighbors := grid2d.gridpos_neighbors_to_idpos_neighbors(gridpos_neighbors)
	mut cost_neighbors := []CellCost{}
	for cell_id in id_neighbors {
		cost := costdata[cell_id]
		step := calc_steps(grid2d.id_to_gridpos(cell_id), mover.target_gridpos)
		has_mover := grid2d.cells[cell_id].has_mover
		registered := grid2d.cells[cell_id].registered
		cost_neighbors << CellCost{cell_id, cost, step, has_mover, registered}
	}

	cost_neighbors = cost_neighbors.filter(it.has_mover == false)
	cost_neighbors = cost_neighbors.filter(it.registered == false)
	cost_neighbors = cost_neighbors.filter(it.cell_id !in mover.visited_cells)
	cost_neighbors.sort(a.cost < b.cost)
	cost_neighbors = cost_neighbors.filter(it.cost == cost_neighbors[0].cost)
	cost_neighbors.sort(a.steps < b.steps)
	return cost_neighbors
}

pub fn (mut mover Mover) find_next_pos(costdata map[int]int, cost_neighbors []CellCost, mut grid2d Grid2d) {
	mover.start_pos = mover.next_pos
	mover.percent_moved = 0

	if cur_cost := costdata[mover.id_pos] {
		if cur_cost <= mover.cost_to_stop {
			return
		}
	}

	if cost_neighbors.len > 0 {
		neighbor_min_cost := cost_neighbors[0]
		new_next_gridpos := grid2d.id_to_gridpos(neighbor_min_cost.cell_id)
		mover.next_pos = grid2d.gridpos_to_pixelpos(new_next_gridpos, true)
		grid2d.cells[neighbor_min_cost.cell_id].register = mover.id
		grid2d.cells[neighbor_min_cost.cell_id].registered = true
	} else {
		mover.visited_cells.clear()
	}

	nxtgridpos := grid2d.pixelpos_to_gridpos(mover.next_pos)
	curgridpos := grid2d.pixelpos_to_gridpos(mover.current_pos)
	dx := nxtgridpos.col - curgridpos.col
	dy := nxtgridpos.row - curgridpos.row
	rotdata := '${dx} ${dy}'
	mover.rot = mygrid2d.rotdata_dict[rotdata]
}

pub fn (mut mover Mover) step_moving(djmaps map[int]map[int]int, mut grid2d Grid2d) bool {
	mover.on_leave_cell(mut grid2d)

	if mover.is_step_reached() {
		mover.grid_pos = grid2d.pixelpos_to_gridpos(mover.current_pos)
		mover.id_pos = grid2d.gridpos_to_id(mover.grid_pos)

		grid2d.cells[mover.id_pos].has_mover = true
		mover.unreg(mover.id_pos, mut grid2d)

		if mover.is_target_reached() {
			mover.visited_cells.clear()
			return false
		}

		target_id := grid2d.gridpos_to_id(mover.target_gridpos)
		end_ids := grid2d.get_cells_around(target_id, 0, 100)
		if end_ids.len > 0 {
			stop_cost := djmaps[mover.costdata_id][end_ids[0]]
			if djmaps[mover.costdata_id][mover.id_pos] <= stop_cost {
				mover.visited_cells.clear()
				mover.target_pos = mover.current_pos
				mover.target_gridpos = grid2d.pixelpos_to_gridpos(mover.target_pos)
				return false
			}
		}

		if mover.id_pos !in mover.visited_cells {
			mover.visited_cells << mover.id_pos
		}

		if costdata := djmaps[mover.costdata_id] {
			cost_neighbors := mover.find_neighbors(costdata, grid2d, grid2d.cross)
			mover.find_next_pos(costdata, cost_neighbors, mut grid2d)
		}
		return false
	}

	mut adjust_speed := f32(1.0)
	is_same_col := mover.start_pos.x - mover.next_pos.x == 0
	is_same_row := mover.start_pos.y - mover.next_pos.y == 0
	if !is_same_col && !is_same_row {
		adjust_speed = 0.7
	}

	mover.current_pos.x = mover.start_pos.x +
		mover.percent_moved * (mover.next_pos.x - mover.start_pos.x)
	mover.current_pos.y = mover.start_pos.y +
		mover.percent_moved * (mover.next_pos.y - mover.start_pos.y)

	mover.percent_moved += mover.percent_speed * adjust_speed
	if mover.percent_moved > 1 {
		mover.percent_moved = 1
	}
	return true
}

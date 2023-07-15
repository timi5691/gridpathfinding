module mygrid2d

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
	rows                    int
	cols                    int
	cell_size               f32
	cross                   bool = true
	cells                   map[int]Cell
	mover_map               map[int]Mover
	djmaps                  map[int]map[int]int
	steps_to_stop           map[int]int
	targets_regs            map[int]map[int]bool
	djmap_just_created_list []int
}

pub struct DjmapChan {
pub mut:
	id    int
	djmap map[int]int
}

pub fn (mut grid2d Grid2d) init_info(cols int, rows int, cell_size f32, cross bool) {
	grid2d.cols = cols
	grid2d.rows = rows
	grid2d.cell_size = cell_size
	grid2d.cross = cross
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

pub fn (grid2d Grid2d) get_cells_around(cell_to int, cross bool) []int {
	if grid2d.cells[cell_to].walkable && !grid2d.cells[cell_to].has_mover {
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
			neighbors := grid2d.cell_get_neighbors(cell_pos, cross)
			mut is_stop := false

			for n in neighbors {
				id_n := grid2d.gridpos_to_id(n)

				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}

				if grid2d.cells[id_n].walkable && !grid2d.cells[id_n].has_mover {
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

pub fn (grid2d Grid2d) find_steps_to_stop(cell_to int, cross bool) int {
	if grid2d.cells[cell_to].walkable && !grid2d.cells[cell_to].has_mover {
		return 0
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
			neighbors := grid2d.cell_get_neighbors(cell_pos, cross)
			mut is_stop := false

			for n in neighbors {
				id_n := grid2d.gridpos_to_id(n)

				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}

				if grid2d.cells[id_n].walkable && !grid2d.cells[id_n].has_mover {
					is_stop = true
				}
			}

			if is_stop {
				return step
			}
		}

		opentable = new_opentable.clone()
		step += 1
	}

	return -1
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

pub fn (grid2d Grid2d) set_mover_target(mut mover Mover, x f32, y f32) {
	pixelpos_click := PixelPos{x, y}
	gridpos_click := grid2d.pixelpos_to_gridpos(pixelpos_click)
	cell_click := grid2d.gridpos_to_id(gridpos_click)
	mover.visited_cells.clear()
	mover.target_pos = pixelpos_click
	mover.target_gridpos = gridpos_click
	mover.costdata_id = cell_click
}

pub fn find_steps_to_stop_to_each_target(grid2d Grid2d) map[int]int {
	mut new_steps_to_stop := grid2d.steps_to_stop.clone()

	for target_id in grid2d.djmaps.keys() {
		new_steps_to_stop[target_id] = grid2d.find_steps_to_stop(target_id, grid2d.cross)
	}

	return new_steps_to_stop
}

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
	percent_speed  f32 = 0.05
	base_speed     f32 = 0.1
	cost_to_stop   int
	visited_cells  []int
	selected       bool
	costdata_id    int = -1
	rot            int
	debug          string
	team           int
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

pub fn reg_unreg_target_cell(mover_id int, cell_click int, mut grid2d Grid2d) {
	for target_cell in grid2d.targets_regs.keys() {
		if _ := grid2d.targets_regs[target_cell][mover_id] {
			grid2d.targets_regs[target_cell].delete(mover_id)

			if grid2d.targets_regs[target_cell].len == 0 {
				if _ := grid2d.djmaps[target_cell] {
					grid2d.djmaps.delete(target_cell)
				}

				grid2d.targets_regs.delete(target_cell)
			}
		}
	}

	grid2d.targets_regs[cell_click][mover_id] = true
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

fn cost_neighbors_filter_not_has_mover(cost_neighbors []CellCost) []CellCost {
	mut rs := []CellCost{}

	for cell_cost in cost_neighbors {
		if !cell_cost.has_mover {
			rs << cell_cost
		}
	}

	return rs
}

fn cost_neighbors_filter_not_registered(cost_neighbors []CellCost) []CellCost {
	mut rs := []CellCost{}

	for cell_cost in cost_neighbors {
		if !cell_cost.registered {
			rs << cell_cost
		}
	}

	return rs
}

fn cost_neighbors_filter_not_in_visited_cells(cost_neighbors []CellCost, visited_cells []int) []CellCost {
	mut rs := []CellCost{}

	for cell_cost in cost_neighbors {
		if cell_cost.cell_id !in visited_cells {
			rs << cell_cost
		}
	}

	return rs
}

fn cost_neighbors_filter_cost(cost_neighbors []CellCost, cost int) []CellCost {
	mut rs := []CellCost{}

	for cell_cost in cost_neighbors {
		if cell_cost.cost == cost {
			rs << cell_cost
		}
	}

	return rs
}

fn cost_neighbors_sort_cost_assending(cost_neighbors []CellCost) []CellCost {
	if cost_neighbors.len < 2 {
		return cost_neighbors
	}

	mut rs := cost_neighbors.clone()
	mut count := 0
	n := rs.len

	for count < n - 1 {
		cell_cost := rs[count]
		cell_cost2 := rs[count + 1]

		if cell_cost.cost > cell_cost2.cost {
			rs[count], rs[count + 1] = rs[count + 1], rs[count]
			count = 0
		} else {
			count += 1
		}
	}

	return rs
}

fn cost_neighbors_sort_steps_assending(cost_neighbors []CellCost) []CellCost {
	if cost_neighbors.len < 2 {
		return cost_neighbors
	}

	mut rs := cost_neighbors.clone()
	mut count := 0
	n := rs.len

	for count < n - 1 {
		cell_cost := rs[count]
		cell_cost2 := rs[count + 1]

		if cell_cost.steps > cell_cost2.steps {
			rs[count], rs[count + 1] = rs[count + 1], rs[count]
			count = 0
		} else {
			count += 1
		}
	}

	return rs
}

fn (mover Mover) find_neighbors(costdata map[int]int, grid2d Grid2d, cross bool) []CellCost {
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

	// cost_neighbors = cost_neighbors.filter(it.has_mover == false)
	// cost_neighbors = cost_neighbors.filter(it.registered == false)
	// cost_neighbors = cost_neighbors.filter(it.cell_id !in mover.visited_cells)
	// cost_neighbors.sort(a.cost < b.cost)
	// cost_neighbors = cost_neighbors.filter(it.cost == cost_neighbors[0].cost)

	cost_neighbors = cost_neighbors_filter_not_has_mover(cost_neighbors)
	cost_neighbors = cost_neighbors_filter_not_registered(cost_neighbors)
	cost_neighbors = cost_neighbors_filter_not_in_visited_cells(cost_neighbors, mover.visited_cells)
	cost_neighbors = cost_neighbors_sort_cost_assending(cost_neighbors)

	if cost_neighbors.len > 0 {
		cost_neighbors = (spawn cost_neighbors_filter_cost(cost_neighbors, cost_neighbors[0].cost)).wait()
		// cost_neighbors.sort(a.steps < b.steps)
		cost_neighbors = (spawn cost_neighbors_sort_steps_assending(cost_neighbors)).wait()
	}

	return cost_neighbors
}

pub fn (mover Mover) find_next_pos(costdata map[int]int, cost_neighbors []CellCost, grid2d Grid2d) PixelPos {
	if cur_cost := costdata[mover.id_pos] {
		if cur_cost <= mover.cost_to_stop {
			return mover.next_pos
		}
	}

	neighbor_min_cost := cost_neighbors[0]
	new_next_gridpos := grid2d.id_to_gridpos(neighbor_min_cost.cell_id)

	return grid2d.gridpos_to_pixelpos(new_next_gridpos, true)
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

		if stop_cost := grid2d.steps_to_stop[target_id] {
			if stop_cost != -1 {
				if djmaps[mover.costdata_id][mover.id_pos] <= stop_cost {
					mover.visited_cells.clear()
					mover.target_pos = mover.current_pos
					mover.target_gridpos = grid2d.pixelpos_to_gridpos(mover.target_pos)
					return false
				}
			}
		}

		if costdata := djmaps[mover.costdata_id] {
			cost_neighbors := mover.find_neighbors(costdata, grid2d, grid2d.cross)
			mover.start_pos = mover.next_pos
			mover.percent_moved = 0

			if cost_neighbors.len == 0 {
				mover.visited_cells.clear()
			} else {
				neighbor_min_cost := cost_neighbors[0]
				grid2d.cells[neighbor_min_cost.cell_id].register = mover.id
				grid2d.cells[neighbor_min_cost.cell_id].registered = true
				mover.next_pos = mover.find_next_pos(costdata, cost_neighbors, grid2d)
			}
		}

		return false
	}

	if mover.id_pos !in mover.visited_cells {
		mover.visited_cells << mover.id_pos
		if mover.visited_cells.len > 16 {
			mover.visited_cells.delete(0)
		}
	}

	is_same_col := mover.start_pos.x - mover.next_pos.x == 0
	is_same_row := mover.start_pos.y - mover.next_pos.y == 0
	adjust_speed := if !is_same_col && !is_same_row { f32(0.7) } else { f32(1.0) }

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

pub fn (mover Mover) calc_mover_rot(grid2d Grid2d) int {
	nxtgridpos := grid2d.pixelpos_to_gridpos(mover.next_pos)
	curgridpos := grid2d.pixelpos_to_gridpos(mover.current_pos)
	dx := nxtgridpos.col - curgridpos.col
	dy := nxtgridpos.row - curgridpos.row
	rotdata := '${dx} ${dy}'
	rotdata_dict := {
		'1 0':   0
		'1 -1':  45
		'0 -1':  90
		'-1 -1': 135
		'-1 0':  180
		'-1 1':  225
		'0 1':   270
		'1 1':   315
		'0 0':   mover.rot
	}

	return rotdata_dict[rotdata]
}

pub fn (mut grid2d Grid2d) update_mover() {
	for _, mut mover in grid2d.mover_map {
		spd_rate := f32(grid2d.cols) / 100.0
		mover.percent_speed = mover.base_speed * spd_rate
		rot := mover.calc_mover_rot(grid2d)
		mover.rot = if rot != -1 { rot } else { mover.rot }
		mover.step_moving(grid2d.djmaps, mut grid2d)
	}
}

pub fn (mut grid2d Grid2d) process_steps_to_stop(ch_sts chan map[int]int) {
	// channel find steps to stop
	spawn fn (the_channel chan map[int]int, the_grid2d Grid2d) {
		the_channel <- find_steps_to_stop_to_each_target(the_grid2d)
	}(ch_sts, grid2d)

	mut a := map[int]int{}

	if ch_sts.try_pop(mut a) == .success {
		grid2d.steps_to_stop = a.clone()
	}
}

pub fn (mut grid2d Grid2d) try_pop_djmap(ch_djmap chan DjmapChan) {
	// channel create dikstra map
	mut b := DjmapChan{}

	if ch_djmap.try_pop(mut b) == .success {
		grid2d.djmaps[b.id] = b.djmap.clone()
		if b.id !in grid2d.djmap_just_created_list {
			grid2d.djmap_just_created_list << b.id
		}

		// if _ := grid2d.djmaps[b.id] {
		// 	app.djmap_test = grid2d.djmaps[b.id].clone()
		// }
	}
}

pub fn create_djmap(grid2d Grid2d, gridpos_click GridPos, cross bool, the_chanel chan DjmapChan) {
	djmap := grid2d.create_dijkstra_map(gridpos_click, cross)
	cell_id := grid2d.gridpos_to_id(gridpos_click)
	the_chanel <- DjmapChan{
		id: cell_id
		djmap: djmap
	}
}

pub fn (grid2d Grid2d) is_just_created_djmap_list_empty() bool {
	return grid2d.djmap_just_created_list.len == 0
}

pub fn (mut grid2d Grid2d) set_selected_movers_destination(mover_team int) {
	if !grid2d.is_just_created_djmap_list_empty() {
		cell_to := grid2d.djmap_just_created_list.last()
		mut has_mover_selected := false
		for mover_id, mut mover in grid2d.mover_map {
			if mover.selected && mover.team == mover_team {
				gridpos_ := grid2d.id_to_gridpos(cell_to)
				pxpos_ := grid2d.gridpos_to_pixelpos(gridpos_, true)
				grid2d.set_mover_target(mut mover, pxpos_.x, pxpos_.y)
				reg_unreg_target_cell(mover_id, cell_to, mut grid2d)
				has_mover_selected = true
			}
		}
		if has_mover_selected {
			grid2d.djmap_just_created_list.delete_last()
		}
	}
}

pub fn (mut grid2d Grid2d) set_selected_movers_cell_to(cell_to int, mover_team int) {
	if _ := grid2d.djmaps[cell_to] {
		for mover_id, mut mover in grid2d.mover_map {
			if mover.selected && mover.team == mover_team {
				gridpos_ := grid2d.id_to_gridpos(cell_to)
				pxpos_ := grid2d.gridpos_to_pixelpos(gridpos_, true)
				grid2d.set_mover_target(mut mover, pxpos_.x, pxpos_.y)
				reg_unreg_target_cell(mover_id, cell_to, mut grid2d)
			}
		}
	}
}


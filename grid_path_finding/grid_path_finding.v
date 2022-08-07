/////////////////////////////////////////////
/// GRID AND PATHFINDING
module grid_path_finding

import math {sqrt}
import gx
import rand

pub struct GridCell {
pub mut:
	pos GridPos
	pixelpos PixelPos
	walkable bool = true

	fl_name string
	fl_future string

	team int = -1
	is_give_way bool
	has_moving bool
	give_way_to int = -1
}

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
	x f32
	y f32
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

pub fn (data GridData) cell_id_to_pixelpos(cell_id int) PixelPos {
	grpos := data.cell_id_to_gridpos(cell_id)
	return data.gridpos_to_pixel_pos(grpos)
}

pub fn (data GridData) get_id_from_pixel_pos(x f32, y f32) int {
	col := int(x/data.cell_size)
	row := int(y/data.cell_size)
	return row*data.cols + col
}

pub fn (data GridData) get_pixel_pos_center_cell_id(cell_id int) PixelPos {
	half_cell_size := data.cell_size/2
	grid_pos := data.cell_id_to_gridpos(cell_id)
	pos := data.gridpos_to_pixel_pos(grid_pos)
	rs := PixelPos{x: pos.x + half_cell_size, y: pos.y + half_cell_size}
	return rs
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
		return dx + dy
	}
	return int(sqrt(dx*dx + dy*dy))
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


fn (data GridData) calculate_path(current int, start int, parents map[int]int) []PixelPos {
	half_cell_size := data.cell_size/2
	mut p := current
	mut pos := data.cell_id_to_pixelpos(p)
	pos.x += half_cell_size
	pos.y += half_cell_size
	mut path := []PixelPos{}
	mut idpath := []int{}
	for p != start {
		path.prepend(pos)
		idpath.prepend(p)
		p = parents[p]
		pos = data.cell_id_to_pixelpos(p)
		pos.x += half_cell_size
		pos.y += half_cell_size
	}
	idpath.prepend(p)
	path.prepend(pos)
	return path
}


pub fn (data GridData) get_walkable_cells() []int {
	mut rs := []int{}
	for cell_id , cell in data.cells {
		if cell.walkable {
			rs << cell_id
		}
	}
	return rs
}


pub fn (data GridData) find_another_next_end(start int, end int) int {
	mut neighbors := data.get_neighbor_ids(end)
	for id, cell in neighbors {
		mut other_neighbors := data.get_neighbor_ids(cell)
		if other_neighbors.len == 0 {
			neighbors.delete(id)
		}
	}
	if neighbors.len != 0 {
		mut cell_id := neighbors.pop()
		mut dist_min := data.path_finding(start, cell_id, true).len
		for cell in neighbors {
			dist := data.path_finding(start, cell, true).len
			if dist < dist_min {
				cell_id = cell
				dist_min = dist
			}
		}
		return cell_id
	}
	return -1
}

pub fn (data GridData) has_cell(cell_id int) bool {
	return cell_id >= 0 && cell_id < data.rows*data.cols
}

pub fn (data GridData) path_finding(start int, to int, optimized bool) []PixelPos {
	mut open := map[int]Cost{}
	mut closed := map[int]Cost{}
	mut parents := map[int]int{}
	mut current := start
	start_pos := data.cell_id_to_pixelpos(current)
	mut path := []PixelPos{}
	mut end := to
	
	is_end_walkable := data.is_cell_walkable(end)
	if !is_end_walkable {
		end = data.find_another_next_end(start, end)
		if end == -1 {
			return [start_pos]
		}
	}

	dist_to_end := data.calc_cost(start, end, optimized)
	open[start] = Cost{
		to_start: 0
		to_end: dist_to_end
		total: dist_to_end
	}


	for open.len != 0 {
		current = find_best_cost(open)
		if current == end {
			path = data.calculate_path(current, start, parents)
			return path
		}
		neighbors := data.get_neighbor_ids(current)
		for neighbor in neighbors {
			to_start_now := open[current].to_start + 1
			if _ := open[neighbor] {
				if open[neighbor].to_start > to_start_now {
					open[neighbor].to_start = to_start_now
					open[neighbor].total = to_start_now + open[neighbor].to_end
					parents[neighbor] = current
				}
			} else if _ := closed[neighbor] {
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
		path = [start_pos]
	}
	return path
}
//////////////////////////////////////////////////////////////////////////////////
/// PATH FOLLOWER

pub struct PathFollower {
pub mut:
	name string
	path []PixelPos
	simple_calc_cost bool = true
	pos PixelPos
	status int // 0 mean stop, 1 mean follow path
	spd f32 = 0.02 // from 0.0 to 1.0
	t f32 // from 0.0 to 1.0
	a f32
	b f32
	step int

	selected bool
	cur_point int
	next_point int
	color gx.Color = gx.green
	change_dir bool
	change_point_to int
	dir string = 'right'
	reg_cell int = -1
	team int

}

pub fn (mut fl PathFollower) set_path(pth_of_pos []PixelPos, grid_data GridData) {
	// set path
	fl.path = pth_of_pos
	fl.path[0] = fl.pos
	
}

pub fn (mut fl PathFollower) start_move(spd f32, grid_data GridData) {
	fl.spd = spd
	fl.t = 0
	fl.step = 0
	fl.status = 1
}

pub fn (mut fl PathFollower) move_to_cell(cell_to int, grid_data GridData) {
	if fl.status == 0 {
		fl_at_cell := grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
		pth := (go grid_data.path_finding(fl_at_cell, cell_to, fl.simple_calc_cost)).wait()
		fl.set_path(pth, grid_data)
		if fl.path.len > 1 {
			fl.start_move(fl.spd, grid_data)
		}
	} else {
		fl.change_point_to = cell_to
		fl.change_dir = true
	}
}

pub fn (mut fl PathFollower) move_to_pos(x f32, y f32, grid_data GridData) {
	cell_to := grid_data.get_id_from_pixel_pos(x, y)
	if fl.status == 0 {
		fl_at_cell := grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
		pth := grid_data.path_finding(fl_at_cell, cell_to, fl.simple_calc_cost)
		fl.set_path(pth, grid_data)
		if fl.path.len > 1 {
			fl.start_move(fl.spd, grid_data)
		}
	} else {
		fl.change_point_to = cell_to
		fl.change_dir = true
	}
}

pub fn (mut fl PathFollower) moving(mut grid_data GridData) {
	if fl.status == 0 {
		fl.cur_point = grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
		grid_data.cells[fl.cur_point].has_moving = false
		
		give_way_to := grid_data.cells[fl.cur_point].give_way_to
		mut empty_neighbors := []int{}
		if give_way_to != -1 {
			mut myneighbors := grid_data.get_neighbor_ids(fl.cur_point)
			if myneighbors.len == 0 {
				return
			}
			for i, v in myneighbors {
				cell := v
				cond1 := cell == give_way_to
				cond2 := grid_data.cells[cell].has_moving == true
				cond3 := grid_data.cells[cell].fl_name == ''
				if cond3 {
					empty_neighbors << v
				}
				if cond1 || cond2 {
					myneighbors.delete(i)
				}
			}
			if empty_neighbors.len != 0 {
				rn := rand.int_in_range(0, empty_neighbors.len) or {panic(err)}
				cell_to := empty_neighbors[rn]
				fl.move_to_cell(cell_to, grid_data)
			} else {
				if myneighbors.len != 0 {
					rn := rand.int_in_range(0, myneighbors.len) or {panic(err)}
					cell_to := myneighbors[rn]
					fl.move_to_cell(cell_to, grid_data)
				}
			}
		}
		return
	}
	
	if fl.path.len < 2 {
		return
	}
	
	fl.cur_point = grid_data.get_id_from_pixel_pos(fl.path[fl.step].x, fl.path[fl.step].y)
	grid_data.cells[fl.cur_point].has_moving = true
	
	fl.pos.x = fl.path[fl.step].x + fl.a*fl.t
	fl.pos.y = fl.path[fl.step].y + fl.b*fl.t
	
	fl.next_point = grid_data.get_id_from_pixel_pos(fl.path[fl.step + 1].x, fl.path[fl.step + 1].y)
	
	// start step
	if fl.t == 0 {

		// change path suddenly
		if fl.change_dir {
			grid_data.staying(fl.cur_point, mut fl)
			new_pth := grid_data.path_finding(fl.cur_point, fl.change_point_to, fl.simple_calc_cost)
			if new_pth.len > 1 {
				fl.set_path(new_pth, grid_data)
				fl.start_move(fl.spd, grid_data)
				fl.change_dir = false
				return
			}
			fl.change_dir = false
		}

		// register next point
		reg_err := grid_data.register_next_point(fl.next_point, mut fl)
		
		if  reg_err == 1 || reg_err == 2 {
			// registered
			fl.reg_cell = fl.next_point
		}

		nextcell_name := grid_data.cells[fl.next_point].fl_name
		nextcell_future := grid_data.cells[fl.next_point].fl_future

		is_next_point_can_move_to := (nextcell_name == '' || nextcell_name == fl.name) && 
		(nextcell_future == '' || nextcell_future == fl.name)

		if !is_next_point_can_move_to {
			is_next_point_is_stop_point_of_other := nextcell_name != fl.name &&
			nextcell_name != '' &&
			nextcell_future == ''

			is_next_point_same_team := grid_data.cells[fl.next_point].team == fl.team
			is_next_point_not_give_way := !grid_data.cells[fl.next_point].is_give_way
			if is_next_point_is_stop_point_of_other && 
			is_next_point_same_team && 
			is_next_point_not_give_way {
				grid_data.cells[fl.next_point].give_way_to = fl.cur_point
				grid_data.cells[fl.next_point].is_give_way = true
			}
			return
		}
		grid_data.cells[fl.next_point].give_way_to = -1
		grid_data.cells[fl.next_point].is_give_way = false
		// set dir
		fl.set_dir()
	}

	fl.a = fl.path[fl.step + 1].x - fl.path[fl.step].x
	fl.b = fl.path[fl.step + 1].y - fl.path[fl.step].y

	// increase t every frame
	fl.t += fl.spd

	// finished a step
	if fl.t >= 1 {
		fl.t = 0
		fl.step += 1
		id_previous := grid_data.get_id_from_pixel_pos(fl.path[fl.step - 1].x, fl.path[fl.step - 1].y)
		fl.cur_point = grid_data.get_id_from_pixel_pos(fl.path[fl.step].x, fl.path[fl.step].y)
		grid_data.staying(fl.cur_point, mut fl)
		grid_data.leave(id_previous, mut fl)
	}

	// finish move
	if fl.step == fl.path.len - 1 {
		fl.pos = fl.path[fl.path.len - 1]
		// id_end := grid_data.get_id_from_pixel_pos(fl.pos.x, fl.pos.y)
		fl.status = 0
	}
}

pub fn (mut grid_data GridData) create_follower(name string, x f32, y f32) PathFollower {
	mut fl := PathFollower{
		name: name
		pos: PixelPos{x: x, y: y}
	}
	fl.cur_point = grid_data.get_id_from_pixel_pos(x, y)
	grid_data.staying(fl.cur_point, mut fl)
	grid_data.cells[fl.cur_point].has_moving = false
	return fl
}



pub fn (mut grid_data GridData) staying(cell_id int, mut fl PathFollower) {
	fl_name := fl.name
	grid_data.cells[cell_id].fl_name = fl_name
	grid_data.next_point_arrived(cell_id, mut fl)
	fl.reg_cell = -1
	grid_data.cells[cell_id].team = fl.team
	if fl.path.len == 0 {
		grid_data.cells[cell_id].has_moving = false
	} else {
		grid_data.cells[cell_id].has_moving = true
	}
	// grid_data.cells[cell_id].walkable = false
}

pub fn (mut grid_data GridData) leave(cell_id int, mut fl PathFollower)  {
	fl_name := fl.name
	if grid_data.cells[cell_id].fl_name == fl_name {
		grid_data.cells[cell_id].team = -1
		grid_data.cells[cell_id].fl_name = ''
		grid_data.cells[cell_id].has_moving = false
		// grid_data.cells[cell_id].walkable = true
	}
}

fn (mut fl PathFollower) set_dir() {
	// set dir
	dir_value := fl.next_point - fl.cur_point
	if dir_value == 1 {
		fl.dir = 'right'
	} else if dir_value == -1 {
		fl.dir = 'left'
	} else if dir_value > 1 {
		fl.dir = 'down'
	} else if dir_value < -1 {
		fl.dir = 'up'
	}
}

fn (mut grid_data GridData) register_next_point(next_point int, mut fl PathFollower) int {
	fl_name := fl.name
	nextcell_name := grid_data.cells[next_point].fl_name
	nextcell_future := grid_data.cells[next_point].fl_future
	hasnt_registered := nextcell_future == ''
	is_empty := nextcell_name == '' || nextcell_name == fl.name
	walkable := grid_data.cells[next_point].walkable
	can_register := hasnt_registered && is_empty && walkable
	if can_register{
		grid_data.cells[next_point].fl_future = fl_name
		return 1
	}
	is_fl_registered := nextcell_future == fl_name
	if is_fl_registered {
		return 2
	}
	return 0
}

fn (mut grid_data GridData) next_point_arrived(next_point int, mut fl PathFollower) int {
	fl_name := fl.name
	if grid_data.cells[next_point].fl_future == fl_name{
		grid_data.cells[next_point].fl_future = ''
		return 1
	}
	return 0
}


module md_grid

import gg
import gx
import my_extra { Rect, Vec2, limit_number, random_number_in_range }
import math

pub struct DjmapRs {
pub mut:
	id int
	rs map[int]int
	// nextcell_map map[int]int
}

///////////////////////////////////////////////////////////////
/// STRUCT GRID
pub struct Grid {
pub mut:
	cam_pos          &Vec2 = &Vec2{}
	pos              Vec2
	draw_pos         Vec2
	cols             int = 100
	rows             int = 100
	cell_size        f32 = 32
	width            f32 = 32.0 * 100
	height           f32 = 32.0 * 100
	cross_dist       f32 = f32(math.sqrt(16 * 16 + 16 * 16))
	steps_map        map[int]map[int]int
	walkable_map     map[int]bool
	not_walkable_ids []int
	walkable_ids     []int
	neighbors_data   map[int][]int
	ch1              chan DjmapRs
	ch2              chan map[int][]int
	color            gx.Color
}

pub fn (grid Grid) id_to_rect(id int) Rect {
	cell_pos := grid.id_to_pixelpos(id, false)
	cell_size_vec := Vec2{grid.cell_size, grid.cell_size}
	return Rect{cell_pos, cell_size_vec}
}

pub fn (grid Grid) gridpos_to_id(gridpos Vec2) int {
	return int(gridpos.y * grid.cols + gridpos.x)
}

pub fn (grid Grid) id_to_gridpos(id int) Vec2 {
	row := id / grid.cols

	return Vec2{
		x: id - row * grid.cols
		y: row
	}
}

pub fn (grid Grid) gridpos_to_pixelpos(gridpos Vec2, center bool) Vec2 {
	if center {
		return Vec2{
			x: gridpos.x * grid.cell_size + grid.cell_size / 2 + grid.pos.x
			y: gridpos.y * grid.cell_size + grid.cell_size / 2 + grid.pos.y
		}
	}

	return Vec2{
		x: gridpos.x * grid.cell_size + grid.pos.x
		y: gridpos.y * grid.cell_size + grid.pos.y
	}
}

pub fn (grid Grid) pixelpos_to_gridpos(pp Vec2) Vec2 {
	return Vec2{
		x: int((pp.x - grid.pos.x) / grid.cell_size)
		y: int((pp.y - grid.pos.y) / grid.cell_size)
	}
}

pub fn (grid Grid) pixelpos_to_id(pp Vec2) int {
	return grid.gridpos_to_id(grid.pixelpos_to_gridpos(pp))
}

pub fn (grid Grid) id_to_pixelpos(id int, center bool) Vec2 {
	return grid.gridpos_to_pixelpos(grid.id_to_gridpos(id), center)
}

pub fn (grid Grid) pixelpos_to_cellcenterpos(pp Vec2) Vec2 {
	return grid.id_to_pixelpos(grid.pixelpos_to_id(pp), true)
}

pub fn (grid Grid) is_pos_in_grid(pos Vec2) bool {
	grpos := grid.pixelpos_to_gridpos(pos)
	if grpos.x > grid.cols || grpos.x < 0 || grpos.y < 0 || grpos.y > grid.rows {
		return false
	}
	return true
}

pub fn (grid Grid) calc_steps(cell1 int, cell2 int) int {
	gp1 := grid.id_to_gridpos(cell1)
	gp2 := grid.id_to_gridpos(cell2)
	return math.abs(int(gp2.x - gp1.x)) + math.abs(int(gp2.y - gp1.y))
}

pub fn (grid Grid) id_get_idneighbors(id int, cross bool) []int {
	gridpos := grid.id_to_gridpos(id)
	mut rs := []int{}
	mut nbup := false
	mut nbdown := false
	mut nbleft := false
	mut nbright := false

	mut next := gridpos.plus(my_extra.vec_up)
	mut cond_row := next.y >= 0 && next.y < grid.rows
	mut cond_col := next.x >= 0 && next.x < grid.cols
	mut nextid := grid.gridpos_to_id(next)
	mut walkable := grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid
		nbup = true
	}

	next = gridpos.plus(my_extra.vec_down)
	cond_row = next.y >= 0 && next.y < grid.rows
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid
		nbdown = true
	}

	next = gridpos.plus(my_extra.vec_left)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbleft = true
	}

	next = gridpos.plus(my_extra.vec_right)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbright = true
	}

	if cross {
		next = gridpos.plus(my_extra.vec_topleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbleft {
			rs << nextid
		}

		next = gridpos.plus(my_extra.vec_topright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbright {
			rs << nextid
		}

		next = gridpos.plus(my_extra.vec_downleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbleft {
			rs << nextid
		}

		next = gridpos.plus(my_extra.vec_downright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbright {
			rs << nextid
		}
	}
	return rs.reverse()
}

pub fn (grid Grid) create_steps_map(dest_id int, cross bool) DjmapRs {
	mut processed_map := {
		dest_id: 0
	}
	// mut nextcell_map := {
	// 	dest_id: dest_id
	// }
	mut open := {
		dest_id: 0
	}
	for open.len > 0 {
		mut new_open := map[int]int{}
		for id, cost in open {
			for nbid in grid.neighbors_data[id] {
				if _ := processed_map[nbid] {
					continue
				}
				processed_map[nbid] = cost + 1
				// nextcell_map[nbid] = id
				new_open[nbid] = cost + 1
			}
		}
		open = new_open.clone()
	}
	return DjmapRs{
		id: dest_id
		rs: processed_map
		// nextcell_map: nextcell_map
	}
}

pub fn (mut grid Grid) create_steps_map_to_pos_in_thread(pos Vec2, cross bool) {
	// mut data := &game.data
	if !grid.is_pos_in_grid(pos) {
		return
	}
	mut cell_id := grid.pixelpos_to_id(pos)
	spawn fn [mut grid, cross] (cell_id int) {
		grid.ch1 <- grid.create_steps_map(cell_id, cross)
	}(cell_id)
}

pub fn (grid Grid) get_walkable_cells() []int {
	mut rs := []int{}
	for id, walkable in grid.walkable_map {
		if walkable {
			rs << id
		}
	}
	return rs
}

pub fn (grid Grid) get_cells_around_in_nround(cell_to int, cur_cell_map map[int]int, cross bool, nround int) []int {
	// if grid.cells[cell_to].walkable {
	// 	return [cell_to]
	// }

	mut costs := {
		cell_to: 0
	}
	mut opentable := [cell_to]
	mut step := 1
	mut rs := []int{}

	for opentable.len != 0 {
		mut new_opentable := []int{}

		for cell in opentable {
			neighbors := grid.neighbors_data[cell]

			for id_n in neighbors {
				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}
			}

			for cell_id in new_opentable {
				mut dk := true
				if _ := cur_cell_map[cell_id] {
					dk = false
				}
				if grid.walkable_map[cell_id] && dk {
					rs << cell_id
				}
			}
		}

		opentable = new_opentable.clone()
		step += 1
		if step > nround {
			return rs
		}
	}

	return []int{}
}

pub fn (mut grid Grid) random_walkable_map(_percent_walkable int) {
	mut percent_walkable := _percent_walkable
	percent_walkable = i32(limit_number(f64(percent_walkable), f64(0), f64(100)))
	ncell := grid.cols * grid.rows
	mut not_walkable_cell := map[int]bool{}
	ncell_not_walkable := ncell - int(f32(percent_walkable) / 100.0 * f32(ncell))
	mut temp_cells := []int{len: ncell, cap: ncell, init: index}
	grid.not_walkable_ids = []int{}
	grid.walkable_ids = []int{}
	for _ in 0 .. ncell_not_walkable {
		nleft := temp_cells.len
		if nleft <= 0 {
			break
		}
		rd_i := random_number_in_range(0, temp_cells.len - 1)
		cid := temp_cells[rd_i]
		not_walkable_cell[cid] = true
		grid.not_walkable_ids << cid
		temp_cells.delete(rd_i)
	}

	for i in 0 .. ncell {
		if _ := not_walkable_cell[i] {
			grid.walkable_map[i] = false
		} else {
			grid.walkable_map[i] = true
			grid.walkable_ids << i
		}
	}

	cross := true
	grid.create_neighbors_data_in_thread(cross)
}

pub fn (grid Grid) get_number_of_cells() int {
	return grid.cols * grid.rows
}

pub fn (mut grid Grid) create_neighbors_data(cross bool) map[int][]int {
	ncell := grid.get_number_of_cells()
	mut rs := map[int][]int{}
	for cell_id in 0 .. ncell {
		rs[cell_id] = grid.id_get_idneighbors(cell_id, cross)
	}
	return rs
}

pub fn (mut grid Grid) create_neighbors_data_in_thread(cross bool) {
	spawn fn [mut grid, cross] () {
		grid.ch2 <- grid.create_neighbors_data(cross)
	}()
}

pub fn (mut grid Grid) update() {
	grid.draw_pos = grid.pos.minus(grid.cam_pos)
	if grid.ch2.try_pop(mut grid.neighbors_data) == .success {
		println('get neighbors data finished')
	}
	mut djmap_result := DjmapRs{}
	if grid.ch1.try_pop(mut djmap_result) == .success {
		grid.steps_map[djmap_result.id] = djmap_result.rs.clone()
	}
}

pub fn (mut grid Grid) draw_self(ctx &gg.Context) {
	for cid in grid.not_walkable_ids {
		cell_pos := grid.id_to_pixelpos(cid, false).minus(grid.cam_pos)
		ctx.draw_rect_filled(cell_pos.x, cell_pos.y, grid.cell_size, grid.cell_size, gx.gray)
	}
}

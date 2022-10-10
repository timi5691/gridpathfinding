module dijkstraforall

import grid2d

pub fn create_dijkstra_map(col_to int, row_to int, grid map[string]map[string]int, is_cross bool) map[string]int {
	mut cell_to := '$col_to $row_to'
	mut costs := {cell_to: 0}
	mut opentable := {cell_to: 0}

	mut step := 1

	for opentable.len != 0 {
		mut new_opentable := map[string]int{}
		for cell, _ in opentable {
			col := grid[cell]['col']
			row := grid[cell]['row']
			neighbors := grid2d.cell_get_neighbors(col, row, grid, is_cross).values()
			for n in neighbors {
				if _ := costs[n] {} else {
					costs[n] = step
					new_opentable[n] = step
				}
			}
		}
		opentable = new_opentable.clone()
		step += 1
	}
	return costs
}
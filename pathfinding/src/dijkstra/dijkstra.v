module dijkstra

import mystructs
import grid2d

pub fn create_dijkstra_map(cell_to int, app mystructs.App) map[int]int {
	mut costs := {cell_to: 0}
	mut opentable := {cell_to: 0}

	mut step := 1

	for opentable.len != 0 {
		mut new_opentable := map[int]int{}
		for cell, _ in opentable {
			// col := app.grid[cell]['col']
			// row := app.grid[cell]['row']
			neighbors := grid2d.cell_get_neighbors(cell, app).values()
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


module astar2d

import mystructs
import grid2d


fn open_get_cell_min_f(open map[int]map[string]int) int {
	mut min_i := open.keys()[0]
	mut min_f := open[min_i]['f']
	for i, _ in open {
		f_i := open[i]['f']
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

pub fn get_path(cell int, cell2 int, app mystructs.App) []int {
	mut path := []int{}
	start := cell
	mut current := cell

	h_start := grid2d.estimate_steps(cell, cell2, app)
	mut open := {current: {'g': 0, 'h': h_start, 'f': h_start}}
	mut closed := map[int]map[string]int{}
	mut parents := map[int]int{}

	for open.len != 0 {
		current = open_get_cell_min_f(open)
		if current == cell2 {
			path = calculate_path(current, start, parents)
			return path
		}
		neighbors := grid2d.cell_get_neighbors(current, app).values()
		for nb in neighbors {
			nb_g := open[current]['g'] + 1
			if _ := open[nb] {
				if open[nb]['g'] > nb_g {
					open[nb]['g'] = nb_g
					open[nb]['f'] = nb_g + open[nb]['h']
					parents[nb] = current
				}
			} else if _ := closed[nb] {
				if closed[nb]['g'] > nb_g {
					closed[nb]['g'] = nb_g
					closed[nb]['f'] = nb_g + closed[nb]['h']
					parents[nb] = current
					open[nb] = closed[nb].clone()
					closed.delete(nb)
				}
			} else {
				nb_h := if app.switches['astar_optimize'] {
					grid2d.estimate_steps(nb, cell2, app)
				} else {
					int(grid2d.distance_two_cells(nb, cell2, app))
				}
				open[nb] = {'g': nb_g, 'h': nb_h, 'f': nb_g + nb_h}
				parents[nb] = current
			}
		}
		closed[current] = open[current].clone()
		open.delete(current)
	}
	if current != cell2{
		path = [cell]
	}
	return path
}
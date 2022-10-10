module astar2d

import grid2d

fn open_get_cell_min_f(open map[string]map[string]int) string {
	cells := open.keys()
	mut min_i := cells[0]
	mut min_f := open[min_i]['f']
	for i in cells {
		f_i := open[i]['f']
		if f_i < min_f {
			min_i = i
			min_f = f_i
		}
	}
	return min_i
}

fn calculate_path(current string, start string, parents map[string]string) []string {
	mut path := []string{}
	mut p := current
	for p != start {
		path.prepend(p)
		p = parents[p]
	}
	path.prepend(p)
	return path
}

pub fn get_path(col1 int, row1 int, col2 int, row2 int, grid map[string]map[string]int, is_cross bool, optimize bool) []string {
	mut path := []string{}
	goal_cell := '$col2 $row2'
	start := '$col1 $row1'
	mut current := '$col1 $row1'

	h_start := grid2d.estimate_steps(col1, row1, col2, row2)
	mut open := {current: {'g': 0, 'h': h_start, 'f': h_start}}
	mut closed := map[string]map[string]int{}
	mut parents := map[string]string{}

	for open.len != 0 {
		current = open_get_cell_min_f(open)
		if current == goal_cell {
			path = calculate_path(current, start, parents)
			return path
		}
		cr_col := grid[current]['col']
		cr_row := grid[current]['row']
		neighbors := grid2d.cell_get_neighbors(cr_col, cr_row, grid, is_cross).values()
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
				nb_h := if optimize
				{
					grid2d.estimate_steps(grid[nb]['col'], grid[nb]['row'], grid[goal_cell]['col'], grid[goal_cell]['row'])
				} else {
					int(grid2d.calc_distance(grid[nb]['col'], grid[nb]['row'], grid[goal_cell]['col'], grid[goal_cell]['row'], 32))
				}
				open[nb] = {'g': nb_g, 'h': nb_h, 'f': nb_g + nb_h}
				parents[nb] = current
			}
		}
		closed[current] = open[current].clone()
		open.delete(current)
	}
	if current != goal_cell{
		path = ['$col1 $row1']
	}
	return path
}
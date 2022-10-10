module mystructs

import gg

pub struct App {
pub mut:
	gg &gg.Context
	walkable_map [][]int
	grid map[string]map[string]int
	cell_size int = 32
	debug string

	// This is the beginning location
	pos1 map[string]int = {'col': 1, 'row': 1}
	
	// this is the destination location
	pos2 map[string]int = {'col': 13, 'row': 17}

	// if is_cross == true, path can cross moving
	is_cross  bool //= true

	// if optimize == false, astar will calculate distance by sqrt
	optimize bool = true

	// path for astar test
	astar_path []string

	// map for dijkstra test
	dijkstra_map map[string]int
}
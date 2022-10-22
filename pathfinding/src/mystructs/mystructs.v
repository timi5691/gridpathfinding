module mystructs

import gg

pub struct App {
pub mut:
	gg &gg.Context
	game_state int // 0: draw wall
	switches map[string]bool = {
		'astar_optimize': true,
		'is_cross': true,
	}

	walkable_map [][]int
	cols int = 10
	rows int = 10
	cell_size int = 32
	half int = 16
	grid map[int]map[string]int

	entities map[int]map[string]int = {
		0: {
			'x': 0*32 + 16,
			'y': 0*32 + 16,
			'xto': 10*32 + 16,
			'yto': 10*32 + 16,
		},
	}
	entity_count int
	deleted_entities []int

	
	debug string = 'press left to draw/erase wall, press c to turn on/off is cross.'

	int_data map[int]map[string]int
	f_data map[int]map[string]f32
	str_data map[int]map[string]string
	
	astar_paths map[int][]int
	dijkstra_maps map[int]map[int]int
	
	// path for astar test
	astar_path []string

	// map for dijkstra test
	dijkstra_map map[string]int

}




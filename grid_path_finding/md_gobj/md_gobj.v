module md_gobj

import gg
import gx
import my_extra { Rect, Vec2, rad_to_deg }
import md_grid { Grid }
import md_animated_sprite { AnimatedSprite }
import math

///////////////////////////////////////////////////////////////
/// STRUCT GOBJ
pub struct Gobj {
pub mut:
	state               string = 'idle'
	id                  int
	debug               string
	cur_pos             Vec2
	next_pos            Vec2
	cur_cell            int
	next_cell           int = -1
	dest_cell           int
	dest_pos            Vec2
	new_dest_pos        Vec2
	spd                 f32 = 1.0
	vel                 Vec2
	vel1                Vec2
	vel2                Vec2
	vel3                Vec2
	vec_length_optimize bool = true
	player_control      bool = true
	player_selected     bool
	visited_cells       []int
	team                int
	see_range           f32 = 128.0
	attack_range        f32 = 32 * 3.0

	scan_vec_list    []Vec2 = []Vec2{}
	died             bool
	nearest_enemy_id int = -1
	nearest_ally_id  int = -1
	lost_hp_ally_id  int = -1

	facing              Vec2 = Vec2{0.0, 1.0}
	in_cam_view         bool
	target_enemy_id     int  = -1
	attack_in_see_range bool = true

	cant_moving          bool
	cant_moving_time     f32
	max_cant_moving_time f32    = 0.2
	gobj_type            string = 'soldier'
	group                int    = -1
	aspr                 AnimatedSprite
	aspr_facing          Vec2
	sat_rot              f32 = 0.0
	sat_length           f32 = 16.0
	nsat                 int = 8
	sat_pos              Vec2
	sat_pos2             Vec2
	sat_pos3             Vec2
	sat_pos4             Vec2
	sat_pos5             Vec2
	sat_pos6             Vec2
	sat_pos7             Vec2
	sat_pos8             Vec2
	nearest_eid          int = -1
	around_cells         []int
	run_away             bool
	right_mouse_pressed  bool
	right_mouse_released bool
	right_mouse_down     bool
	left_mouse_pressed   bool
	left_mouse_released  bool
	left_mouse_down      bool
	double_left_click    bool
	attack_e_id          int = -1
	attack_time          f32 = 0.0
	time_reset_attack    f32 = 1.0
	is_resetting_attack  bool
	is_attacked          bool
	max_hp               f32 = 150.0
	hp                   f32 = 150.0
	old_hp               f32 = 150.0
	is_hurt              bool
	hurt_time            f32 = -1
}

pub fn (mut gobj Gobj) set_new_dest_pos(dest_pos Vec2) {
	gobj.new_dest_pos = dest_pos
}

pub fn (gobj Gobj) find_next_cell(grid Grid, nextcell_map map[int]int) int {
	cur_cell := grid.pixelpos_to_id(gobj.cur_pos)
	mut rs := cur_cell
	dest_cell := grid.pixelpos_to_id(gobj.dest_pos)
	if _ := grid.neighbors_data[cur_cell] {
		if _ := grid.steps_map[dest_cell] {
			mut best_cost := grid.steps_map[dest_cell][cur_cell]
			mut best_steps := grid.calc_steps(cur_cell, dest_cell)
			for neighbor in grid.neighbors_data[cur_cell] {
				if nbid := nextcell_map[neighbor] {
					if nbid != gobj.id {
						continue
					}
				}
				if neighbor in gobj.visited_cells {
					continue
				}
				cost := grid.steps_map[dest_cell][neighbor]
				steps := grid.calc_steps(cur_cell, neighbor)
				if cost < best_cost {
					rs = neighbor
					best_cost = cost
				} else if cost == best_cost {
					if steps < best_steps {
						rs = neighbor
						best_cost = cost
						best_steps = steps
					}
				}
			}
		}
	}
	return rs
}

pub fn (gobj Gobj) simple_find_next_cell(grid Grid, nextcell_map map[int]int) int {
	ab := gobj.dest_pos.minus(gobj.cur_pos)
	mut min_dist := ab.x * ab.x + ab.y * ab.y
	mut rs := gobj.cur_cell
	if neighbors := grid.neighbors_data[gobj.cur_cell] {
		for nb in neighbors {
			if nb_gobjid := nextcell_map[nb] {
				if nb_gobjid != gobj.id {
					continue
				}
			}
			if nb in gobj.visited_cells {
				continue
			}
			nb_pos := grid.id_to_pixelpos(nb, true)
			nbab := gobj.dest_pos.minus(nb_pos)
			nb_dist := nbab.x * nbab.x + nbab.y * nbab.y
			if nb_dist < min_dist {
				rs = nb
				min_dist = nb_dist
			}
		}
	}
	return rs
}

pub fn (gobj Gobj) is_destination_reached() bool {
	return gobj.cur_pos == gobj.dest_pos
}

pub fn (gobj Gobj) is_next_pos_reached() bool {
	return gobj.cur_pos == gobj.next_pos
}

pub fn (gobj Gobj) is_pos_center_cell(grid Grid) bool {
	center_pos := grid.id_to_pixelpos(gobj.cur_cell, true)
	return gobj.cur_pos == center_pos
}

pub fn (gobj Gobj) calculate_vel1(grid Grid, delta_time f32) Vec2 {
	if gobj.is_destination_reached() {
		return Vec2{0, 0}
	}
	if gobj.is_next_pos_reached() {
		return Vec2{0, 0}
	}
	cn := gobj.next_pos.minus(gobj.cur_pos)
	cn_length := cn.length()
	if cn_length <= gobj.spd * delta_time * 100.0 {
		return gobj.next_pos.minus(gobj.cur_pos)
	}
	cn_nor := cn.n_split(cn_length)
	return cn_nor.n_times(gobj.spd * delta_time * 100.0)
}

pub fn (mut gobj Gobj) control_aspr_rot(gobj_map map[int]Gobj) {
	if gobj.state == 'attacking nearest enemy' {
		if gobj.nearest_eid != -1 {
			if e := gobj_map[gobj.nearest_eid] {
				to_e_vec := e.cur_pos.minus(gobj.cur_pos)
				mut rot := int(rad_to_deg(to_e_vec.get_angle_radians()))
				if rot < 0 {
					rot += 360
				}
				gobj.aspr.rot = -rot
			}
		}
		return
	}
	if gobj.facing != gobj.aspr_facing {
		if rot := my_extra.rot_facing_map[gobj.facing.str()] {
			gobj.aspr.rot = rot
		}
		gobj.aspr_facing = gobj.facing
	}
}

pub fn (mut gobj Gobj) reg_cur_cell(grid Grid, mut cell_gobj_map map[int]int) {
	if gobj.is_next_pos_reached() {
		cur_cell := gobj.cur_cell
		new_cur_cell := grid.pixelpos_to_id(gobj.cur_pos)
		if new_cur_cell != cur_cell {
			cell_gobj_map[new_cur_cell] = gobj.id
			if id := cell_gobj_map[cur_cell] {
				if id == gobj.id {
					cell_gobj_map.delete(cur_cell)
				}
			}
			gobj.cur_cell = new_cur_cell
		} else {
			cell_gobj_map[new_cur_cell] = gobj.id
			if _ := cell_gobj_map[cur_cell] {
			} else {
				gobj.cur_cell = new_cur_cell
			}
		}
	}
}

pub fn (mut gobj Gobj) on_destination_changed() {
	if gobj.is_next_pos_reached() {
		if gobj.new_dest_pos != gobj.dest_pos {
			gobj.visited_cells.clear()
			gobj.dest_pos = gobj.new_dest_pos
		}
	}
}

pub fn (mut gobj Gobj) reg_next_cell(grid Grid, mut nextcell_map map[int]int) {
	if gobj.is_next_pos_reached() {
		next_cell := gobj.find_next_cell(grid, nextcell_map)
		old_next_cell := gobj.next_cell
		if old_next_cell != next_cell {
			gobj.next_pos = grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			old_next_gridpos := grid.id_to_gridpos(old_next_cell)
			next_gridpos := grid.id_to_gridpos(next_cell)
			gobj.facing = next_gridpos.minus(old_next_gridpos)
		}

		if id := nextcell_map[old_next_cell] {
			if id == gobj.id {
				nextcell_map.delete(old_next_cell)
			}
		}
		nextcell_map[next_cell] = gobj.id
	}
}

pub fn (mut gobj Gobj) simple_reg_next_cell(grid Grid, mut nextcell_map map[int]int) {
	if gobj.is_next_pos_reached() {
		next_cell := gobj.simple_find_next_cell(grid, nextcell_map)
		old_next_cell := gobj.next_cell
		if old_next_cell != next_cell {
			gobj.next_pos = grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			old_next_gridpos := grid.id_to_gridpos(old_next_cell)
			next_gridpos := grid.id_to_gridpos(next_cell)
			gobj.facing = next_gridpos.minus(old_next_gridpos)
		}

		if id := nextcell_map[old_next_cell] {
			if id == gobj.id {
				nextcell_map.delete(old_next_cell)
			}
		}
		nextcell_map[next_cell] = gobj.id
	}
}

pub fn (mut gobj Gobj) begin_moving(grid Grid) {
	gobj.dest_cell = grid.pixelpos_to_id(gobj.dest_pos)
}

pub fn (mut gobj Gobj) moving_to_destination(grid Grid, mut cell_gobj_map map[int]int, mut nextcell_map map[int]int, delta_time f32) {
	if gobj.hp <= 0 {
		return
	}
	if gobj.is_next_pos_reached() {
		gobj.on_destination_changed()
		gobj.reg_cur_cell(grid, mut cell_gobj_map)
		gobj.reg_next_cell(grid, mut nextcell_map)
		//
	}
	gobj.vel1 = gobj.calculate_vel1(grid, delta_time)
	gobj.vel = gobj.vel1.plus(gobj.vel2).plus(gobj.vel3)
	gobj.cur_pos = gobj.cur_pos.plus(gobj.vel)

	gobj.stop_moving_if_cant_moving_too_long(delta_time)
}

pub fn (mut gobj Gobj) simple_moving_to_destination(grid Grid, mut cell_gobj_map map[int]int, mut nextcell_map map[int]int, delta_time f32) {
	if gobj.hp <= 0 {
		return
	}
	gobj.on_destination_changed()
	gobj.reg_cur_cell(grid, mut cell_gobj_map)
	gobj.simple_reg_next_cell(grid, mut nextcell_map)
	gobj.vel1 = gobj.calculate_vel1(grid, delta_time)
	gobj.vel = gobj.vel1.plus(gobj.vel2).plus(gobj.vel3)
	gobj.cur_pos = gobj.cur_pos.plus(gobj.vel)

	gobj.stop_moving_if_cant_moving_too_long(delta_time)
}

pub fn (mut gobj Gobj) stop_moving_if_cant_moving_too_long(delta_time f32) {
	gobj.cant_moving = !gobj.is_destination_reached() && gobj.next_pos == gobj.cur_pos
	if !gobj.cant_moving {
		gobj.cant_moving_time = 0.0
		return
	}
	gobj.cant_moving_time += delta_time
	if gobj.cant_moving_time >= gobj.max_cant_moving_time && gobj.is_next_pos_reached() {
		gobj.stop_moving()
	}
}

pub fn (mut gobj Gobj) stop_moving_if_hp_zero(mut cell_gobj_map map[int]int, mut nextcell_map map[int]int) {
	if gobj.hp == 0 {
		gobj.unreg_curcell_nextcell(mut cell_gobj_map, mut nextcell_map)
		gobj.stop_moving()
	}
}

pub fn (mut gobj Gobj) unreg_curcell_nextcell(mut cell_gobj_map map[int]int, mut nextcell_map map[int]int) {
	if id := cell_gobj_map[gobj.cur_cell] {
		if id == gobj.id {
			cell_gobj_map.delete(gobj.cur_cell)
		}
	}
	if id := nextcell_map[gobj.next_cell] {
		if id == gobj.id {
			nextcell_map.delete(gobj.next_cell)
		}
	}
}

pub fn (mut gobj Gobj) stop_moving() {
	gobj.cant_moving_time = 0
	gobj.new_dest_pos = gobj.cur_pos
	gobj.dest_pos = gobj.cur_pos
}

pub fn (mut gobj Gobj) rereg_next_cell_to_cur_cell(grid Grid, mut nextcell_map map[int]int) {
	if !gobj.is_next_pos_reached() {
		old_next_cell := gobj.next_cell
		next_cell := gobj.cur_cell
		gobj.next_cell = next_cell
		gobj.next_pos = grid.id_to_pixelpos(next_cell, true)
		gobj.visited_cells.clear()
		if _ := nextcell_map[old_next_cell] {
			nextcell_map.delete(old_next_cell)
		}
		nextcell_map[next_cell] = gobj.id
	}
}

pub fn (mut gobj Gobj) rotate_sat(delta f32) {
	gobj.sat_rot += 0.1 * 100.0 * delta
	if gobj.sat_rot >= 2.0 * math.pi / f32(8) {
		gobj.sat_rot = 0.0
		gobj.sat_length += 16.0
		if gobj.sat_length >= 240 {
			gobj.sat_length = 16
		}
	}

	gobj.sat_pos = gobj.cur_pos.plus(my_extra.vec_right.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos2 = gobj.cur_pos.plus(my_extra.vec_down.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos3 = gobj.cur_pos.plus(my_extra.vec_left.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos4 = gobj.cur_pos.plus(my_extra.vec_up.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos5 = gobj.cur_pos.plus(my_extra.vec_downleft.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos6 = gobj.cur_pos.plus(my_extra.vec_downright.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos7 = gobj.cur_pos.plus(my_extra.vec_topleft.n_times(gobj.sat_length).rotate(gobj.sat_rot))
	gobj.sat_pos8 = gobj.cur_pos.plus(my_extra.vec_topright.n_times(gobj.sat_length).rotate(gobj.sat_rot))
}

pub fn (mut gobj Gobj) draw_sats(mut ctx gg.Context, cam_pos Vec2) {
	draw_pos := gobj.cur_pos.minus(cam_pos)
	ctx.draw_circle_empty(draw_pos.x, draw_pos.y, 16, gx.green)

	sat_draw_pos := gobj.sat_pos.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos.x, sat_draw_pos.y, 4, gx.yellow)

	sat_draw_pos2 := gobj.sat_pos2.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos2.x, sat_draw_pos2.y, 4, gx.yellow)

	sat_draw_pos3 := gobj.sat_pos3.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos3.x, sat_draw_pos3.y, 4, gx.yellow)

	sat_draw_pos4 := gobj.sat_pos4.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos4.x, sat_draw_pos4.y, 4, gx.yellow)

	sat_draw_pos5 := gobj.sat_pos5.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos5.x, sat_draw_pos5.y, 4, gx.yellow)

	sat_draw_pos6 := gobj.sat_pos6.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos6.x, sat_draw_pos6.y, 4, gx.yellow)

	sat_draw_pos7 := gobj.sat_pos7.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos7.x, sat_draw_pos7.y, 4, gx.yellow)

	sat_draw_pos8 := gobj.sat_pos8.minus(cam_pos)
	ctx.draw_circle_empty(sat_draw_pos8.x, sat_draw_pos8.y, 4, gx.yellow)
}

fn (mut gobj Gobj) check_cell_id_for_nearest_enemy_id(cell_id int, cell_gobj_map map[int]int, gobj_map map[int]Gobj) {
	if eid := cell_gobj_map[cell_id] {
		if e := gobj_map[eid] {
			if eid != gobj.id && e.team != gobj.team && e.hp > 0 {
				if gobj.nearest_eid == -1 {
					gobj.nearest_eid = eid
				} else {
					if e0 := gobj_map[gobj.nearest_eid] {
						if e0.hp > 0 {
							to_e0_vec := e0.cur_pos.minus(gobj.cur_pos)
							e0dist := to_e0_vec.x * to_e0_vec.x + to_e0_vec.y * to_e0_vec.y

							to_e_vec := e.cur_pos.minus(gobj.cur_pos)
							edist := to_e_vec.x * to_e_vec.x + to_e_vec.y * to_e_vec.y

							if edist < e0dist {
								gobj.nearest_eid = eid
							}
						} else {
							gobj.nearest_eid = eid
						}
					}
				}
			}
		}
	}
}

pub fn (mut gobj Gobj) find_nearest_enemy(grid Grid, cell_gobj_map map[int]int, gobj_map map[int]Gobj) {
	if gobj.hp <= 0 {
		return
	}
	id1 := grid.pixelpos_to_id(gobj.sat_pos)
	id2 := grid.pixelpos_to_id(gobj.sat_pos2)
	id3 := grid.pixelpos_to_id(gobj.sat_pos3)
	id4 := grid.pixelpos_to_id(gobj.sat_pos4)
	id5 := grid.pixelpos_to_id(gobj.sat_pos5)
	id6 := grid.pixelpos_to_id(gobj.sat_pos6)
	id7 := grid.pixelpos_to_id(gobj.sat_pos7)
	id8 := grid.pixelpos_to_id(gobj.sat_pos8)

	gobj.check_cell_id_for_nearest_enemy_id(id1, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id2, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id3, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id4, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id5, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id6, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id7, cell_gobj_map, gobj_map)
	gobj.check_cell_id_for_nearest_enemy_id(id8, cell_gobj_map, gobj_map)
}

pub fn (gobj Gobj) get_rect() Rect {
	return gobj.aspr.get_rect()
}

pub fn (mut gobj Gobj) control_attack_time(delta f32) {
	if gobj.is_resetting_attack {
		gobj.attack_time += delta
		if gobj.attack_time >= gobj.time_reset_attack {
			gobj.is_resetting_attack = false
		}
	}
}

pub fn (mut gobj Gobj) attack_enemy(mut gobj_map map[int]Gobj) {
	unsafe {
		if _ := gobj_map[gobj.attack_e_id] {
			gobj_map[gobj.attack_e_id].hp -= 30
			if gobj_map[gobj.attack_e_id].hp < 0 {
				gobj_map[gobj.attack_e_id].hp = 0
			}
			defer { gobj.attack_e_id = -1 }
		}
	}
}

pub fn (gobj Gobj) get_attack_enemy_id(gobj_map map[int]Gobj) int {
	if gobj.hp <= 0 {
		return -1
	}
	if gobj.is_resetting_attack && gobj.attack_e_id == -1 {
		return -1
	}
	if _ := gobj_map[gobj.attack_e_id] {
		return gobj.attack_e_id
	}
	return -1
}

pub fn (mut gobj Gobj) check_is_hurt(delta f32) {
	if gobj.old_hp != gobj.hp {
		gobj.is_hurt = true
		gobj.old_hp = gobj.hp
		if gobj.hurt_time == -1 {
			gobj.hurt_time = 0.0
		}
	}
	if gobj.hurt_time > -1 {
		gobj.hurt_time += delta
	}
	if gobj.hurt_time >= 0.1 {
		gobj.hurt_time = -1
	}
}

pub fn (mut gobj Gobj) hurt_end() {
	gobj.is_hurt = false
}

pub fn (mut gobj Gobj) check_change_state(gobj_map map[int]Gobj) {
	match gobj.state {
		'idle' {
			if gobj.nearest_eid != -1 {
				if e := gobj_map[gobj.nearest_eid] {
					to_e_vec := e.cur_pos.minus(gobj.cur_pos)
					e_dist := to_e_vec.x * to_e_vec.x + to_e_vec.y * to_e_vec.y
					if e_dist <= gobj.attack_range * gobj.attack_range {
						gobj.state = 'attacking nearest enemy'
					} else if e_dist <= gobj.see_range * gobj.see_range {
						gobj.set_new_dest_pos(e.cur_pos)
						gobj.state = 'chasing nearest enemy'
					} else if !gobj.is_destination_reached() {
						gobj.state = 'moving to destination'
					}
				}
			} else if !gobj.is_destination_reached() {
				gobj.state = 'moving to destination'
			}
		}
		'moving to destination' {
			if gobj.is_next_pos_reached() || gobj.is_destination_reached() {
				if gobj.nearest_eid != -1 {
					if e := gobj_map[gobj.nearest_eid] {
						to_e_vec := e.cur_pos.minus(gobj.cur_pos)
						e_dist := to_e_vec.x * to_e_vec.x + to_e_vec.y * to_e_vec.y
						if e_dist <= gobj.attack_range * gobj.attack_range {
							gobj.state = 'attacking nearest enemy'
						} else if e_dist <= gobj.see_range * gobj.see_range {
							gobj.set_new_dest_pos(e.cur_pos)
							gobj.state = 'chasing nearest enemy'
						} else if gobj.is_destination_reached() {
							gobj.state = 'idle'
						}
					}
				} else if gobj.is_destination_reached() {
					gobj.state = 'idle'
				}
			}
		}
		'chasing nearest enemy' {
			if gobj.is_next_pos_reached() || gobj.is_destination_reached() {
				if gobj.nearest_eid != -1 {
					if e := gobj_map[gobj.nearest_eid] {
						if e.hp > 0 {
							to_e_vec := e.cur_pos.minus(gobj.cur_pos)
							e_dist := to_e_vec.x * to_e_vec.x + to_e_vec.y * to_e_vec.y
							if e_dist <= gobj.attack_range * gobj.attack_range {
								gobj.stop_moving()
								gobj.state = 'attacking nearest enemy'
							} else if e_dist >= gobj.see_range {
								gobj.state = 'idle'
							}
						} else {
							gobj.nearest_eid = -1
							gobj.state = 'idle'
						}
					} else {
						gobj.nearest_eid = -1
						gobj.state = 'idle'
					}
				} else {
					gobj.state = 'idle'
				}
			}
		}
		'attacking nearest enemy' {
			if gobj.right_mouse_pressed && gobj.player_selected {
				gobj.state = 'run away'
			}
			if gobj.nearest_eid != -1 {
				if e := gobj_map[gobj.nearest_eid] {
					if e.hp > 0 {
						to_e_vec := e.cur_pos.minus(gobj.cur_pos)
						e_dist := to_e_vec.x * to_e_vec.x + to_e_vec.y * to_e_vec.y
						if e_dist > gobj.attack_range * gobj.attack_range {
							if e_dist <= gobj.see_range * gobj.see_range {
								gobj.state = 'chasing nearest enemy'
							}
						} else {
							if !gobj.is_resetting_attack {
								gobj.attack_time = 0.0
								gobj.attack_e_id = e.id
								gobj.is_resetting_attack = true
							}
						}
					} else {
						gobj.nearest_eid = -1
						gobj.state = 'idle'
					}
				} else {
					gobj.nearest_eid = -1
					gobj.state = 'idle'
				}
			} else if gobj.is_destination_reached() {
				gobj.state = 'idle'
			}
		}
		'run away' {
			if gobj.is_destination_reached() {
				gobj.state = 'idle'
			}
		}
		else {}
	}
}

module md_user_extra

import gg
import gx
import my_extra { Rect, Vec2, is_pos_in_rect, is_rect_in_rect }
import md_animated_sprite { ActionFrame, AnimatedSprite }
import md_grid { Grid }
import md_gobj { Gobj }

pub fn test(aspr AnimatedSprite) Rect {
	offset := Vec2{
		x: aspr.offset.x * aspr.scale.x
		y: aspr.offset.y * aspr.scale.y
	}
	return Rect{
		pos:  aspr.pos.minus(offset)
		size: aspr.size.multiply(aspr.scale)
	}
}

pub fn create_number_of_gobj_at_random_cell(n int, grid Grid) map[int]Gobj {
	mut gobj_map := map[int]Gobj{}
	mut walkable_ids := grid.walkable_ids.clone()
	my_extra.shuffle(mut walkable_ids)
	for i in 0 .. n {
		cid := walkable_ids.pop()
		pos := grid.id_to_pixelpos(cid, true)
		gobj_team := my_extra.random_number_in_range(1, 2)
		mut gobj := Gobj{
			id:           i
			cur_cell:     cid
			dest_cell:    cid
			next_cell:    cid
			cur_pos:      pos
			next_pos:     pos
			dest_pos:     pos
			new_dest_pos: pos
			aspr:         AnimatedSprite{
				pos:        Vec2{32 * 0 + 16, 32 * 0 + 16}
				offset:     Vec2{16, 16}
				action_map: {
					'moving': [
						ActionFrame{
							img_name: 'test_unit'
							tile_x:   0
							tile_y:   0
							tile_w:   32
							tile_h:   32
						},
						ActionFrame{
							img_name: 'test_unit'
							tile_x:   0
							tile_y:   32
							tile_w:   32
							tile_h:   32
						},
					]
				}
				action:     'moving'
				fps:        10
				size:       Vec2{32, 32}
				scale:      Vec2{1.0*grid.cell_size/32.0, 1.0*grid.cell_size/32.0}
				rot:        -45 * 2
				// color: gx.blue //if gobj_team == 1{gx.blue} else {gx.red}
			}
			team:         gobj_team
		}
		gobj.aspr.start('moving')
		gobj_map[i] = gobj
	}
	return gobj_map
}

pub fn check_gobj_player_selected(mut gobj Gobj, left_mouse_pressed bool, left_mouse_released bool, select_area_rect Rect, mouse_pos Vec2, cell_size f32, double_click_selecting bool, double_click_select_gteam int, double_click_select_gtype string) {
	if gobj.hp <= 0 {
		gobj.player_selected = false
		return
	}
	if double_click_selecting {
		if gobj.team == double_click_select_gteam && gobj.gobj_type == double_click_select_gtype
			&& gobj.in_cam_view {
			gobj.player_selected = true
		} else {
			gobj.player_selected = false
		}
		return
	}
	if left_mouse_released {
		if is_pos_in_rect(gobj.cur_pos, select_area_rect) {
			gobj.player_selected = true
			return
		}
	}
	if left_mouse_pressed {
		gobj.player_selected = my_extra.abs(mouse_pos.x - gobj.cur_pos.x) <= cell_size / 2
			&& my_extra.abs(mouse_pos.y - gobj.cur_pos.y) <= cell_size / 2
	}
}

pub fn draw_rect_empty(rect Rect, mut ctx gg.Context, cl gx.Color) {
	ctx.draw_rect_empty(rect.pos.x, rect.pos.y, rect.size.x, rect.size.y, cl)
}

pub fn draw_test_steps_map(mut ctx gg.Context, test_dest_cell_id int, grid Grid, cam_rect Rect) {
	if test_dest_cell_id != -1 {
		if test_steps_map := grid.steps_map[test_dest_cell_id] {
			for cid, steps in test_steps_map {
				center_pos := grid.id_to_pixelpos(cid, true)
				draw_pos := center_pos.minus(cam_rect.pos)
				cell_rect := grid.id_to_rect(cid)
				if is_rect_in_rect(cell_rect, cam_rect) {
					ctx.draw_text2(gg.DrawTextParams{
						x:              int(draw_pos.x)
						y:              int(draw_pos.y)
						text:           '${steps}'
						color:          gx.white
						align:          .center
						vertical_align: .middle
					})
				}
			}
		}
	}
}

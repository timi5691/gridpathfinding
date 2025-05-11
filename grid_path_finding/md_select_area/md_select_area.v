module md_select_area

import gg
import gx
import my_extra {Vec2, Rect, is_rect_in_rect, is_pos_in_rect}

///////////////////////////////////////////////////////////////
// STRUCT SELECTAREA
pub struct SelectArea {
pub mut:
	visible bool
	cam_pos &Vec2 = &Vec2{}
	x1   f32
	x2   f32
	y1   f32
	y2   f32
	renx f32
	reny f32
	renw f32
	renh f32
	rect Rect
}

pub fn (mut select_area SelectArea) calc_rect_info(click_pos Vec2, mouse_pos Vec2) {
	select_area.x1 = click_pos.x
	select_area.y1 = click_pos.y
	select_area.x2 = mouse_pos.x
	select_area.y2 = mouse_pos.y
	if mouse_pos.x < click_pos.x {
		select_area.x1 = mouse_pos.x
		select_area.x2 = click_pos.x
	}
	if mouse_pos.y < click_pos.y {
		select_area.y1 = mouse_pos.y
		select_area.y2 = click_pos.y
	}
	select_area.rect = Rect{
		pos: Vec2{select_area.x1, select_area.y1}
		size: Vec2{select_area.x2 - select_area.x1, select_area.y2 - select_area.y1}
	}
}

pub fn (mut select_area SelectArea) calc_ren_info(click_pos Vec2, mouse_pos Vec2) {
	select_area.renx = if mouse_pos.x > click_pos.x {
		click_pos.x - select_area.cam_pos.x
	} else {
		mouse_pos.x - select_area.cam_pos.x
	}
	select_area.reny = if mouse_pos.y > click_pos.y {
		click_pos.y - select_area.cam_pos.y
	} else {
		mouse_pos.y - select_area.cam_pos.y
	}
	select_area.renw = if mouse_pos.x > click_pos.x {
		mouse_pos.x - click_pos.x
	} else {
		click_pos.x - mouse_pos.x
	}
	select_area.renh = if mouse_pos.y > click_pos.y {
		mouse_pos.y - click_pos.y
	} else {
		click_pos.y - mouse_pos.y
	}
}

pub fn (select_area SelectArea) is_pos_in(pos Vec2) bool {
	in_x := pos.x >= select_area.x1 && pos.x <= select_area.x2
	in_y := pos.y >= select_area.y1 && pos.y <= select_area.y2
	return in_x && in_y
}

pub fn (select_area SelectArea) is_rect_in(rect Rect) bool {
	return is_rect_in_rect(select_area.rect, rect)
}

pub fn (select_area SelectArea) draw_self(mut ctx gg.Context) {
	if !select_area.visible {return}
	ctx.draw_rect_empty(int(select_area.renx), int(select_area.reny), int(select_area.renw), int(select_area.renh), gx.green)
}
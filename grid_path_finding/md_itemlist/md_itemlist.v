module md_itemlist

import gg
import gx
import math

/////////////////////////////////////////////////////////////////////////////////////
/// ITEM LIST

pub struct IconInfo {
pub mut:
	img_name string
	tile_x int
	tile_y int
	tile_w int
	tile_h int
}

pub struct ItemInfo {
pub mut:
	name string
	amount int
}

pub struct ItemListEvent {
pub mut:
	left_mouse_pressed bool
	mouse_click_gui_x f32
	mouse_click_gui_y f32
	is_key_pressed_right bool
	is_key_pressed_left bool
	is_key_pressed_down bool
	is_key_pressed_up bool
}

pub struct ItemList {
pub mut:
	active bool = true
	visible bool = true
	gui_x f32 = 32
	gui_y f32 = 32
	width f32 = 160
	height f32 = 120
	item_info map[string]ItemInfo
	nslot int = 5
	page int = 1
	selected_item string
	selected_slot int
	rect_color gx.Color = gx.black
	cl_name gx.Color = gx.white
	cl_amount gx.Color = gx.green
	ev ItemListEvent
}

pub fn (itlist ItemList) get_number_of_items() int {
	return itlist.item_info.len
}

pub fn (itlist ItemList) get_total_pages() int {
	return i32(math.ceil(f32(itlist.get_number_of_items())/f32(itlist.nslot)))
}

pub fn (itlist ItemList) calc_slot_height() f32 {
	return itlist.height/itlist.nslot
}

pub fn (itlist ItemList) calc_begin_idx() int {
	return (itlist.page - 1)*itlist.nslot
}

pub fn (itlist ItemList) slot_idx_to_item_idx(slot_idx int) int {
	begin_idx := itlist.calc_begin_idx()
	return begin_idx + slot_idx
}

pub fn (mut itlist ItemList) to_next_page() {
	new_from := itlist.page*itlist.nslot
	nitem := itlist.item_info.len
	if new_from < nitem - 1 {
		itlist.page += 1
		itlist.select_no_item()
	}
}

pub fn (mut itlist ItemList) to_previous_page() {
	if itlist.page - 1 >= 1 {
		itlist.page -= 1
		itlist.select_no_item()
	}
}

pub fn (mut itlist ItemList) select_no_item() {
	itlist.selected_item = ''
	itlist.selected_slot = -1
}

pub fn is_guipos_in_guirect(gpos_x f32, gpos_y f32, grect_x f32, grect_y f32, grect_w f32, grect_h f32) bool {
	a := gpos_x >= grect_x && gpos_x <= grect_x + grect_w
	b := gpos_y >= grect_y && gpos_y <= grect_y + grect_h
	return a && b
}

pub fn (itlist ItemList) is_item_idx_valid(item_idx int) bool {
	nitem := itlist.get_number_of_items()
	return item_idx >= 0 && item_idx < nitem
}

pub fn (itlist ItemList) is_any_item_selected() bool {
	return itlist.selected_slot != -1
}

pub fn (itlist ItemList) is_empty() bool {
	return itlist.item_info.len == 0
}

pub fn (mut itlist ItemList) select_item_at_guipos(gui_x f32, gui_y f32) {
	if !is_guipos_in_guirect(gui_x, gui_y, itlist.gui_x, itlist.gui_y, itlist.width, itlist.height) {
		return
	}
	if !itlist.active || !itlist.visible{
		return
	}
	slot_height := itlist.calc_slot_height()
	dy := gui_y - itlist.gui_y
	itlist.selected_slot = int(dy/slot_height)
	if itlist.is_item_idx_valid(itlist.slot_idx_to_item_idx(itlist.selected_slot)) {
		itlist.selected_item = itlist.get_item_name_from_slot(itlist.selected_slot)
		return
	}
	itlist.select_no_item()
}

pub fn (itlist ItemList) is_item_exists(it_name string) bool {
	if _ := itlist.item_info[it_name] {return true}
	return false
}

pub fn (mut itlist ItemList) remove_item(it_name string) {
	if !itlist.is_item_exists(it_name) {return}
	itlist.item_info.delete(it_name)
	if it_name == itlist.selected_item {
		itlist.select_no_item()
	}
}

pub fn (mut itlist ItemList) use_item(it_name string, it_amount int) {
	if !itlist.is_item_exists(it_name) {return}
	if itlist.item_info[it_name].amount > it_amount {
		itlist.item_info[it_name].amount -= it_amount
		return
	}
	itlist.remove_item(it_name)
}

pub fn (mut itlist ItemList) get_item_name_from_slot(slot_idx int) string {
	return itlist.item_info.keys()[itlist.slot_idx_to_item_idx(itlist.selected_slot)]
}

pub fn (mut itlist ItemList) process() {
	if !itlist.active || !itlist.visible {
		return
	}
	if itlist.ev.left_mouse_pressed {
		itlist.select_item_at_guipos(itlist.ev.mouse_click_gui_x, itlist.ev.mouse_click_gui_y)
	}
	if itlist.ev.is_key_pressed_right {
		itlist.to_next_page()
	} else if itlist.ev.is_key_pressed_left {
		itlist.to_previous_page()
	}
	begin_idx := itlist.calc_begin_idx()
	nitem := itlist.get_number_of_items()
	min_nslot := nitem - begin_idx - 1
	if nitem > 0 {
		if nitem - begin_idx >= itlist.nslot {
			if itlist.ev.is_key_pressed_down {
				itlist.selected_slot += 1
				if itlist.selected_slot >= itlist.nslot {
					itlist.selected_slot = 0
				}
			} else if itlist.ev.is_key_pressed_up {
				itlist.selected_slot -= 1
				if itlist.selected_slot < 0 {
					itlist.selected_slot = itlist.nslot - 1
				}
			}
		} else {
			if itlist.ev.is_key_pressed_down {
				itlist.selected_slot += 1
				if itlist.selected_slot > min_nslot {
					itlist.selected_slot = 0
				}
			} else if itlist.ev.is_key_pressed_up {
				itlist.selected_slot -= 1
				if itlist.selected_slot < 0 {
					itlist.selected_slot = min_nslot
				}
			}
		}
	}
	if itlist.selected_slot != -1 {
		itlist.selected_item = itlist.get_item_name_from_slot(itlist.selected_slot)
	} else {
		itlist.selected_item = ''
	}
}

pub fn (mut itlist ItemList) draw_items(mut ctx gg.Context) {
	if !itlist.visible {
		return
	}
	// draw itemlist rect
	ctx.draw_rect_empty(itlist.gui_x, itlist.gui_y, itlist.width, itlist.height, itlist.rect_color)
	
	// draw item name and amout
	slot_height := itlist.calc_slot_height()
	from := itlist.calc_begin_idx()
	mut to := itlist.nslot*itlist.page
	if to >= itlist.item_info.len {
		to = itlist.item_info.len
	}
	for i in from..to{
		items := itlist.item_info.keys()
		it_name := items[i]
		it_amount := itlist.item_info[it_name].amount
		ctx.draw_text2(gg.DrawTextParams{
			x: int(itlist.gui_x)
			y: int(itlist.gui_y + i*slot_height - (itlist.page - 1)*itlist.height)
			text: ' ${it_name}'
			color: itlist.cl_name
			align: .left
			max_width: int(itlist.width)
		})
		ctx.draw_text2(gg.DrawTextParams{
			x: int(itlist.gui_x + itlist.width)
			y: int(itlist.gui_y + i*slot_height - (itlist.page - 1)*itlist.height)
			text: 'x${it_amount} '
			color: itlist.cl_amount
			align: .right
			max_width: int(itlist.width)
		})
	}

	// draw cursor select item
	if itlist.selected_slot != -1 {
		cursor_y := itlist.gui_y + itlist.selected_slot*slot_height
		// ctx.draw_rect_filled(itlist.gui_x + 1, cursor_y + 1, itlist.width - 2, slot_height - 2, gx.rgba(0, 100, 0, 100))
		ctx.draw_rect_empty(itlist.gui_x + 1, cursor_y + 1, itlist.width - 2, slot_height - 2, gx.rgba(255, 255, 255, 200))
	}

	// draw item current page and total pages
	y_draw_page := itlist.gui_y + itlist.height
	ctx.draw_text2(gg.DrawTextParams{
		x: int(itlist.gui_x + itlist.width)
		y: int(y_draw_page + slot_height/2)
		text: 'page: ${itlist.page}/${itlist.get_total_pages()}'
		color: gx.Color{255, 255, 255, 255}
		align: .right
		vertical_align: .middle
	})
}

pub fn (mut itlist ItemList) draw_items_with_icons(mut ctx gg.Context, img_map map[string]&gg.Image, icon_map map[string]IconInfo) {
	if !itlist.visible {
		return
	}
	// draw itemlist rect
	ctx.draw_rect_filled(itlist.gui_x, itlist.gui_y, itlist.width, itlist.height, itlist.rect_color)
	ctx.draw_rect_empty(itlist.gui_x, itlist.gui_y, itlist.width, itlist.height, gx.white)
	nitem := itlist.get_number_of_items()
	if nitem == 0 {
		return
	}
	total_pages := itlist.get_total_pages()
	if itlist.page > total_pages {
		itlist.page = total_pages
	}
	slot_height := itlist.calc_slot_height()
	from := itlist.calc_begin_idx()
	dritname_x := itlist.gui_x
	dritamount_x := itlist.gui_x + itlist.width
	// draw item name and amount
	mut to := itlist.nslot*itlist.page
	if to >= itlist.item_info.len {
		to = itlist.item_info.len
	}
	for i in from..to{
		dr_y := itlist.gui_y + i*slot_height - (itlist.page - 1)*itlist.height
		items := itlist.item_info.keys()
		it_name := items[i]
		it_amount := itlist.item_info[it_name].amount
		ctx.draw_text2(gg.DrawTextParams{
			x: int(dritname_x)
			y: int(dr_y + slot_height/2)
			text: ' ${it_name}'
			color: itlist.cl_name
			align: .left
			vertical_align: .middle
			max_width: int(itlist.width)
		})
		if icon_inf := icon_map[it_name] {
			driticon_x := itlist.gui_x + itlist.width - ctx.text_width('x${it_amount} ') - slot_height
			img_name := icon_inf.img_name
			img := img_map[img_name] or {panic('loi')}
			ctx.draw_image_with_config(gg.DrawImageConfig{
				img: img
				img_rect: gg.Rect{driticon_x, dr_y, slot_height, slot_height}
				part_rect: gg.Rect{icon_inf.tile_x, icon_inf.tile_y, icon_inf.tile_w, icon_inf.tile_h}
				rotation: 0
				color: gx.white
				effect: .add
			})
		}
		ctx.draw_text2(gg.DrawTextParams{
			x: int(dritamount_x)
			y: int(dr_y + slot_height/2)
			text: 'x${it_amount} '
			color: itlist.cl_amount
			align: .right
			vertical_align: .middle
			max_width: int(itlist.width)
		})
	}

	// draw cursor select item
	if itlist.selected_slot != -1 {
		cursor_y := itlist.gui_y + itlist.selected_slot*slot_height
		// ctx.draw_rect_filled(itlist.gui_x + 1, cursor_y + 1, itlist.width - 2, slot_height - 2, gx.rgba(0, 100, 0, 100))
		ctx.draw_rect_empty(itlist.gui_x + 1, cursor_y + 1, itlist.width - 2, slot_height - 2, gx.rgba(255, 255, 255, 200))
	}

	// draw item current page and total pages
	y_draw_page := itlist.gui_y + itlist.height
	ctx.draw_text2(gg.DrawTextParams{
		x: int(itlist.gui_x + itlist.width)
		y: int(y_draw_page + slot_height/2)
		text: 'page: ${itlist.page}/${itlist.get_total_pages()}'
		color: gx.Color{255, 255, 255, 255}
		align: .right
		vertical_align: .middle
	})
}

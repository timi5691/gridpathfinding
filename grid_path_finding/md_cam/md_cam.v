module md_cam

import gg
import my_extra {Vec2, Rect}

/////////////////////////////////////////////////////////////////////////////////////
/// Camera

pub struct Camera {
pub mut:
	pos Vec2
	size Vec2
	center_pos Vec2
	zoom f32 = 1.0
	vel Vec2
	margin int = 64
	spd f32 = 4.0
	rect Rect
}

pub fn (mut cam Camera) update(grid_size Vec2, mouse_gui_pos Vec2, delta f32) {
	ws := gg.window_size()
	// update pos
	cam.pos = cam.pos.plus(cam.vel)
	if cam.pos.x < 0 {
		cam.pos.x = 0
	} else if cam.pos.x > grid_size.x - ws.width {
		cam.pos.x = grid_size.x - ws.width
	}
	if cam.pos.y < 0 {
		cam.pos.y = 0
	} else if cam.pos.y > grid_size.y - ws.height {
		cam.pos.y = grid_size.y - ws.height
	}

	camspd := cam.spd*delta*100.0
	if mouse_gui_pos.x <= cam.margin {
		cam.vel.x = -camspd
	} else if mouse_gui_pos.x >= ws.width - cam.margin {
		cam.vel.x = camspd
	} else {
		cam.vel.x = 0
	}
	if mouse_gui_pos.y <= cam.margin {
		cam.vel.y = -camspd
	} else if mouse_gui_pos.y >= ws.height - cam.margin {
		cam.vel.y = camspd
	} else {
		cam.vel.y = 0
	}

	cam.size = Vec2{ws.width, ws.height}
	cam.center_pos.x = cam.pos.x + cam.size.x/2
	cam.center_pos.y = cam.pos.y + cam.size.y/2
	cam.rect = Rect{cam.pos, cam.size}
}
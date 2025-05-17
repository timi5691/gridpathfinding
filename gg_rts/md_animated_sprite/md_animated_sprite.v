module md_animated_sprite

import gg
import gx
import my_extra { Rect, Vec2 }

/////////////////////////////////////////////////////////////////////////////////////
/// ANIMATED SPRITE

pub struct ActionFrame {
pub mut:
	img_name string
	tile_x   int
	tile_y   int
	tile_w   int
	tile_h   int
}

pub struct AnimatedSprite {
pub mut:
	cam_pos     &Vec2 = &Vec2{}
	draw_pos    Vec2
	pos         Vec2
	rect        Rect
	draw_rect   Rect
	offset      Vec2
	action_map  map[string][]ActionFrame
	action      string
	frame_value f32
	frame_idx   int
	fps         f32 = 5.0
	playing     bool
	loop        bool = true
	// color gx.Color = gx.white
	scale Vec2 = Vec2{1, 1}
	size  Vec2 = Vec2{32, 32}
	rot   int
}

pub fn (aspr AnimatedSprite) get_current_action_nframe() int {
	return aspr.action_map[aspr.action].len
}

pub fn (mut aspr AnimatedSprite) start(action string) {
	if _ := aspr.action_map[action] {
		aspr.action = action
		aspr.frame_idx = 0
		aspr.frame_value = 0.0
		aspr.playing = true
	}
}

pub fn (mut aspr AnimatedSprite) stop() {
	aspr.frame_idx = 0
	aspr.frame_value = 0.0
	aspr.playing = false
}

pub fn (aspr AnimatedSprite) get_rect() Rect {
	offset := Vec2{
		x: aspr.offset.x * aspr.scale.x
		y: aspr.offset.y * aspr.scale.y
	}
	return Rect{
		pos:  aspr.pos.minus(offset)
		size: aspr.size.multiply(aspr.scale)
	}
}

pub fn (mut aspr AnimatedSprite) update(delta f32) {
	if !aspr.playing {
		return
	}
	nframe := aspr.get_current_action_nframe()
	if nframe == 0 {
		return
	}

	aspr.frame_value += aspr.fps * delta
	aspr.frame_idx = int(aspr.frame_value)
	if aspr.frame_idx >= nframe {
		if aspr.loop {
			aspr.frame_idx = 0
			aspr.frame_value = 0
			return
		}
		aspr.frame_idx = nframe - 1
	}
	offset := Vec2{
		x: aspr.offset.x * aspr.scale.x
		y: aspr.offset.y * aspr.scale.y
	}
	aspr.rect = Rect{
		pos:  aspr.pos.minus(offset)
		size: aspr.size.multiply(aspr.scale)
	}
	aspr.draw_rect = Rect{
		pos:  aspr.pos.minus(offset).minus(aspr.cam_pos)
		size: aspr.size.multiply(aspr.scale)
	}
	aspr.draw_pos = aspr.pos.minus(aspr.cam_pos).minus(offset)
}

pub fn (mut aspr AnimatedSprite) draw_self(mut ctx gg.Context, img_map map[string]&gg.Image, cl gx.Color) {
	if aspr.action == '' {
		return
	}
	action_frame := aspr.action_map[aspr.action][aspr.frame_idx]
	img := img_map[action_frame.img_name] or { panic('loi') }

	ctx.draw_image_with_config(gg.DrawImageConfig{
		img:       img
		img_rect:  gg.Rect{aspr.draw_pos.x, aspr.draw_pos.y, action_frame.tile_w * aspr.scale.x, action_frame.tile_h * aspr.scale.y}
		part_rect: gg.Rect{action_frame.tile_x, action_frame.tile_y, action_frame.tile_w, action_frame.tile_h}
		rotation:  aspr.rot
		color:     cl
		effect:    .add
	})
}

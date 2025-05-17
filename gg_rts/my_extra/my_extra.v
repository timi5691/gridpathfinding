module my_extra

import math
import rand
import rand.seed

pub const vec_up = Vec2{0, -1}
pub const vec_down = Vec2{0, 1}
pub const vec_left = Vec2{-1, 0}
pub const vec_right = Vec2{1, 0}
pub const vec_topleft = Vec2{-1, -1}
pub const vec_topright = Vec2{1, -1}
pub const vec_downleft = Vec2{-1, 1}
pub const vec_downright = Vec2{1, 1}
pub const rot_facing_map = {
	vec_right.str():     0
	vec_topright.str():  45
	vec_up.str():        90
	vec_topleft.str():   135
	vec_left.str():      180
	vec_downleft.str():  225
	vec_down.str():      270
	vec_downright.str(): 315
}

/////////////////////////////////////////////////////////////////////////////////////
/// Convenient

/// check simple collision
pub fn is_pos_in_rect(pos Vec2, rect Rect) bool {
	in_x := pos.x >= rect.pos.x && pos.x <= rect.pos.x + rect.size.x
	in_y := pos.y >= rect.pos.y && pos.y <= rect.pos.y + rect.size.y
	return in_x && in_y
}

pub fn is_rect_in_rect(rect1 Rect, rect2 Rect) bool {
	rect1_topleft := rect1.get_topleft()
	rect1_topright := rect1.get_topright()
	rect1_botleft := rect1.get_botleft()
	rect1_botright := rect1.get_botright()

	return is_pos_in_rect(rect1_topleft, rect2) || is_pos_in_rect(rect1_topright, rect2)
		|| is_pos_in_rect(rect1_botleft, rect2) || is_pos_in_rect(rect1_botright, rect2)
}

pub fn is_two_pos_in_distance(pos1 Vec2, pos2 Vec2, distance f32) bool {
	dx := pos1.x - pos2.x
	dy := pos1.y - pos2.y
	if dx * dx + dy * dy <= distance * distance {
		return true
	}
	return false
}

/// convert
pub fn guipos_to_realpos(guipos Vec2, campos Vec2) Vec2 {
	return guipos.plus(campos)
}

pub fn rad_to_deg(rad f32) f32 {
	return f32(rad * 180 / math.pi)
}

pub fn deg_to_rad(deg f32) f32 {
	return f32(deg * math.pi / 180)
}

pub fn fastinvsqrt(x f32) f32 {
	mut i := unsafe { *&int(&x) } // get bits for floating value
	i = 1597463007 - (i >> 1) // gives initial guess
	y := unsafe { *&f32(&i) } // convert bits back to float
	rs := 1.0 / y * (1.5 - 0.5 * x * y * y) // Newton step
	// rs2 := f32(math.floor(rs))
	// rs3 := f32(math.ceil(rs))
	// if rs2*rs2 == x {
	// 	return rs2
	// }
	// if rs3*rs3 == x {
	// 	return rs3
	// }
	return rs
}

/// random
pub fn randomize() {
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
}

pub fn random_number_in_range(a int, b int) int {
	return rand.int_in_range(a, b + 1) or { return a - 1 }
}

pub fn shuffle(mut id_list []int) {
	rand.shuffle(mut id_list) or { panic(err) }
}

pub fn abs(number f32) f32 {
	return math.abs(number)
}

pub fn sqrt(number f64) f64 {
	return math.sqrt(number)
}

/// other
pub fn limit_number(number f64, smallest f64, largest f64) f64 {
	if number < smallest {
		return smallest
	}
	if number > largest {
		return largest
	}
	return number
}

pub fn lerp(start f32, end f32, t f32) f32 {
	return start + (end - start) * t
}

pub fn ceil(x f32) f32 {
	return f32(math.ceil(x))
}

/////////////////////////////////////////////////////////////////////////////////////
/// Vec2

pub struct Vec2 {
pub mut:
	x f32
	y f32
}

pub fn (vec Vec2) length() f32 {
	return f32(math.sqrt(vec.x * vec.x + vec.y * vec.y))
}

pub fn (vec Vec2) minus(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x - vec2.x
		y: vec.y - vec2.y
	}
}

pub fn (vec Vec2) plus(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x + vec2.x
		y: vec.y + vec2.y
	}
}

pub fn (vec Vec2) n_times(n f32) Vec2 {
	return Vec2{
		x: vec.x * n
		y: vec.y * n
	}
}

pub fn (vec Vec2) n_split(n f32) Vec2 {
	return Vec2{
		x: vec.x / n
		y: vec.y / n
	}
}

pub fn (vec Vec2) multiply(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x * vec2.x
		y: vec.y * vec2.y
	}
}

pub fn (vec Vec2) divide(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x / vec2.x
		y: vec.y / vec2.y
	}
}

pub fn (vec Vec2) normalize() Vec2 {
	distance := vec.length()
	return vec.n_split(distance)
}

pub fn (vec Vec2) rotate(angle f32) Vec2 {
	return Vec2{
		x: int(vec.x * math.cos(angle) - vec.y * math.sin(angle))
		y: int(vec.x * math.sin(angle) + vec.y * math.cos(angle))
	}
}

pub fn (vec Vec2) get_angle_radians() f32 {
	return f32(math.atan2(f64(vec.y), f64(vec.x)))
}

/////////////////////////////////////////////////////////////////////////////////////
/// Rect

pub struct Rect {
pub mut:
	pos  Vec2
	size Vec2
}

pub fn (rect Rect) get_topleft() Vec2 {
	return rect.pos
}

pub fn (rect Rect) get_topright() Vec2 {
	return Vec2{
		x: rect.pos.x + rect.size.x
		y: rect.pos.y
	}
}

pub fn (rect Rect) get_botleft() Vec2 {
	return Vec2{
		x: rect.pos.x
		y: rect.pos.y + rect.size.y
	}
}

pub fn (rect Rect) get_botright() Vec2 {
	return Vec2{
		x: rect.pos.x + rect.size.x
		y: rect.pos.y + rect.size.y
	}
}

pub fn (rect Rect) get_center() Vec2 {
	return Vec2{
		x: rect.pos.x + (rect.pos.x + rect.size.x) / 2
		y: rect.pos.y + (rect.pos.y + rect.size.y) / 2
	}
}

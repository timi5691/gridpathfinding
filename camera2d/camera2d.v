module camera2d

pub struct Camera2d {
pub mut:
	x int
	y int
}

pub fn create_camera2d(posx int, posy int) Camera2d {
	return Camera2d {
		x: posx
		y: posy
	}
}

pub fn (mut c Camera2d) set_pos(posx int, posy int) {
	c.x = posx
	c.y = posy
}

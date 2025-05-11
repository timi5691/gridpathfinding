module md_explosion

import gg
import rand
import time
import math
import gx 

pub struct Particle {
pub mut:
	x f32
	y f32
	radius f32
	color gg.Color
	velocity_x f32
	velocity_y f32
	lifespan f32
}

pub struct Explosion {
pub mut:
	x f32
	y f32
	particles []Particle
	duration f32
	start_time f64
	initial_radius f32
	finished bool
}

pub fn new_particle(x f32, y f32, initial_radius f32, initial_color gg.Color, initial_velocity_x f32, initial_velocity_y f32, lifespan f32) Particle {
	return Particle{
		x: x
		y: y
		radius: initial_radius
		color: initial_color
		velocity_x: initial_velocity_x
		velocity_y: initial_velocity_y
		lifespan: lifespan
	}
}

pub fn new_explosion(x f32, y f32, num_particles int, initial_radius f32, duration f32) Explosion {
	mut particles := []Particle{}
	for _ in 0 .. num_particles {
		angle := rand.f32() * 2 * math.pi
		speed := rand.f32() * 50 + 20
		vx_f64 := speed * math.cos(angle)
		vy_f64 := speed * math.sin(angle)
		lifespan_f64 := rand.f32() * duration
		alpha := rand.f32() * 200 + 55
		r := u8(rand.int_in_range(100, 256) or { panic(err) })
		g := u8(rand.int_in_range(100, 256) or { panic(err) })
		b := u8(rand.int_in_range(100, 256) or { panic(err) })
		a := u8(alpha)
		color := gx.rgba(r, g, b, a)
		p := new_particle(x, y, initial_radius * (rand.f32() * 0.5 + 0.5), color, f32(vx_f64), f32(vy_f64), f32(lifespan_f64))
		particles << p
	}
	return Explosion{
		x: x
		y: y
		particles: particles
		duration: duration
		start_time: f64(time.now().unix())
		initial_radius: initial_radius
	}
}

pub fn (mut e Explosion) update(dt f32) {
	elapsed_time := f32(f64(time.now().unix()) - e.start_time)
	mut remaining_particles := []Particle{}
	mut count := 0
	for mut p in e.particles {
		p.x += p.velocity_x * dt
		p.y += p.velocity_y * dt
		p.radius -= e.initial_radius * dt / p.lifespan
		mut alpha_factor := 1 - (elapsed_time / p.lifespan)
		if alpha_factor < 0 {
			alpha_factor = 0
		}
		p.color.a = u8(255 * alpha_factor)

		p.lifespan -= dt
		if p.lifespan > 0 {
			remaining_particles << p
			count += 1
		}
	}
	e.particles = remaining_particles
	if count == 0 {
		e.finished = true
	}
}

pub fn (e Explosion) draw(mut ctx gg.Context, camx f32, camy f32) {
	for p in e.particles {
		if p.radius > 0 && p.color.a > 0 {
			ctx.draw_circle_filled(p.x- camx, p.y - camy, p.radius, p.color)
		}
	}
}

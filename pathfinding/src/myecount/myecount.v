module myecount

pub struct EWorld {
pub mut:
	entity_count int
	available_entities []int
	deleted_entities []int
}

pub fn (mut world EWorld) new_entity() int {
	if world.deleted_entities.len != 0 {
		new_entity := world.deleted_entities.pop()
		world.available_entities << new_entity
		return new_entity
	}
	new_entity := world.entity_count
	world.available_entities << new_entity
	world.entity_count += 1
	return new_entity
}

pub fn (mut world EWorld) get_entity_idx(e int) int {
	for i in 0 .. world.available_entities.len {
		if world.available_entities[i] == e {
			return i
		}
	}
	return -1
}

pub fn (mut world EWorld) delete_entity(e int) bool {
	e_idx := world.get_entity_idx(e)
	if e_idx == -1 {
		return false
	}
	world.available_entities.delete(e_idx)
	world.deleted_entities << e
	return true
}

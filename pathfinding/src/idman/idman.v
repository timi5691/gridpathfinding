module idman

pub struct IdManager {
pub mut:
	id_count int
	available_ids []int
	deleted_ids []int
}

pub fn (mut idm IdManager) create_new_id() int {
	if idm.deleted_ids.len != 0 {
		new_id := idm.deleted_ids.pop()
		idm.available_ids << new_id
		return new_id
	}
	new_id := idm.id_count
	idm.available_ids << new_id
	idm.id_count += 1
	return new_id
}

pub fn (mut idm IdManager) get_id_index_in_available_ids(e int) int {
	for i in 0 .. idm.available_ids.len {
		if idm.available_ids[i] == e {
			return i
		}
	}
	return -1
}

pub fn (mut idm IdManager) delete_id(e int) bool {
	e_idx := idm.get_id_index_in_available_ids(e)
	if e_idx == -1 {
		return false
	}
	idm.available_ids.delete(e_idx)
	idm.deleted_ids << e
	return true
}

module md_save_load_data

import os
import os.asset
import json

pub fn save_data[T](data T, file_name string, base_dir string) {
	path := asset.get_path(base_dir, file_name)
	mut f := os.create(path) or {
		panic(err)
	}
	f.write_struct[T](data) or {panic(err)}
	f.close()
	println('write success')
}

pub fn load_data[T](file_name string, base_dir string) T {
	path := asset.get_path(base_dir, file_name)
	mut rs := T{}
	mut f := os.open(path) or {
        panic('error reading file $path')
        return rs
    }
	f.read_struct[T](mut rs) or {panic(err)}
	return rs
}




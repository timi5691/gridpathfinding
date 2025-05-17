module md_sound_player

import os.asset
import miniaudio as ma

pub struct SoundPlayer {
pub mut:
	engine &ma.Engine = &ma.Engine{}
}

pub fn (mut sp SoundPlayer) init_engine() {
	result := ma.engine_init(ma.null, sp.engine)
	if result != .success {
		panic('Failed to initialize audio engine.')
	}
}

pub fn (mut sp SoundPlayer) play(base_dir string, file_name string) {
	wav_file := asset.get_path(base_dir, file_name)
	if ma.engine_play_sound(sp.engine, wav_file.str, ma.null) != .success {
		panic('Failed to load and play "${wav_file}".')
	}
}

pub fn (mut sp SoundPlayer) uninit_engine() {
	ma.engine_uninit(sp.engine)
}
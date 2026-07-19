extends Node
## 资源验证测试：PNG 不空、JSON 合法、音频可播放

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_run_all()


func _run_all() -> void:
	_tf.start_suite("resources")
	
	_tf.run_test("player p1 PNGs (15+)", _check_pngs("res://assets/characters/player/p1", 15))
	_tf.run_test("enemies PNGs (5+)", _check_pngs("res://assets/characters/enemies", 5))
	_tf.run_test("base tiles (50+)", _check_pngs("res://assets/environments/tiles/base", 50))
	_tf.run_test("ice tiles (50+)", _check_pngs("res://assets/environments/tiles/ice", 50))
	_tf.run_test("candy tiles (50+)", _check_pngs("res://assets/environments/tiles/candy", 50))
	
	_tf.run_test("player has idle", _check_sf_anim("res://resources/player/player_sprite_frames.tres", "idle"))
	_tf.run_test("player has walk", _check_sf_anim("res://resources/player/player_sprite_frames.tres", "walk"))
	_tf.run_test("player has jump", _check_sf_anim("res://resources/player/player_sprite_frames.tres", "jump"))
	_tf.run_test("player has hurt", _check_sf_anim("res://resources/player/player_sprite_frames.tres", "hurt"))
	_tf.run_test("player has 15+ frames", _check_sf_count("res://resources/player/player_sprite_frames.tres", 15))
	
	for b in ["greyr1", "frost", "rotlord", "goldguard", "fireheart", "greendruid", "onyx"]:
		_tf.run_test("%s sprite frames" % b, _check_sf_anim("res://resources/bosses/%s_sprite_frames.tres" % b, "idle"))
	
	for e in ["knight", "archer", "mage"]:
		_tf.run_test("%s sprite frames" % e, _check_sf_anim("res://resources/enemies/%s_sprite_frames.tres" % e, "idle"))
	
	_tf.run_test("7 chapter tilesets", _check_tilesets([
		"res://resources/tilesets/chapter_1_tileset.tres",
		"res://resources/tilesets/chapter_2_tileset.tres",
		"res://resources/tilesets/chapter_3_tileset.tres",
		"res://resources/tilesets/chapter_4_tileset.tres",
		"res://resources/tilesets/chapter_5_tileset.tres",
		"res://resources/tilesets/chapter_6_tileset.tres",
		"res://resources/tilesets/chapter_7_tileset.tres",
	]))
	
	for ch in range(1, 8):
		_tf.run_test("ch%d_intro.json valid" % ch, _check_json("res://dialogs/chapter_%d_intro.json" % ch))
		_tf.run_test("ch%d_boss_intro.json valid" % ch, _check_json("res://dialogs/chapter_%d_boss_intro.json" % ch))
		_tf.run_test("ch%d_boss_defeat.json valid" % ch, _check_json("res://dialogs/chapter_%d_boss_defeat.json" % ch))
	
	_tf.run_test("7 BGMs", _check_audio_count("res://audio/bgm", 7))
	_tf.run_test("5+ SFX", _check_audio_count("res://audio/sfx", 5))
	_tf.run_test("base_player_stats.tres", _check_resource("res://resources/player/base_player_stats.tres"))
	for b in ["greyr1", "frost", "rotlord", "goldguard", "fireheart", "greendruid", "onyx"]:
		_tf.run_test("%s_stats.tres" % b, _check_resource("res://resources/bosses/%s_stats.tres" % b))
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _check_pngs(dir: String, min_count: int) -> Callable:
	return func() -> Dictionary:
		var d = DirAccess.open(dir)
		if d == null:
			return {"pass": false, "message": "Directory not found: " + dir}
		var count = 0
		d.list_dir_begin()
		var entry = d.get_next()
		while entry != "":
			if entry.ends_with(".png") and not entry.ends_with(".import"):
				count += 1
			entry = d.get_next()
		d.list_dir_end()
		if count < min_count:
			return {"pass": false, "message": "Only %d PNGs (need %d) in %s" % [count, min_count, dir]}
		return {"pass": true}


func _check_sf_anim(path: String, anim: String) -> Callable:
	return func() -> Dictionary:
		if not ResourceLoader.exists(path):
			return {"pass": false, "message": "Resource not found: " + path}
		var sf = load(path)
		if sf == null:
			return {"pass": false, "message": "Failed to load: " + path}
		if not sf.has_animation(anim):
			return {"pass": false, "message": "Animation '%s' missing in %s" % [anim, path]}
		return {"pass": true}


func _check_sf_count(path: String, min_count: int) -> Callable:
	return func() -> Dictionary:
		var sf = load(path)
		var total = 0
		for a in sf.get_animation_names():
			total += sf.get_frame_count(a)
		if total < min_count:
			return {"pass": false, "message": "Only %d frames (need %d) in %s" % [total, min_count, path]}
		return {"pass": true}


func _check_tilesets(paths: Array) -> Callable:
	return func() -> Dictionary:
		for p in paths:
			if not ResourceLoader.exists(p):
				return {"pass": false, "message": "TileSet missing: " + p}
		return {"pass": true}


func _check_json(path: String) -> Callable:
	return func() -> Dictionary:
		if not FileAccess.file_exists(path):
			return {"pass": false, "message": "JSON not found: " + path}
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {"pass": false, "message": "Failed to open: " + path}
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json == null:
			return {"pass": false, "message": "Invalid JSON in: " + path}
		if not json is Dictionary:
			return {"pass": false, "message": "JSON not a Dict in: " + path}
		if not json.has("lines"):
			return {"pass": false, "message": "JSON missing 'lines' in: " + path}
		if json["lines"].size() == 0:
			return {"pass": false, "message": "JSON has empty 'lines' in: " + path}
		return {"pass": true}


func _check_audio_count(dir: String, min_count: int) -> Callable:
	return func() -> Dictionary:
		var d = DirAccess.open(dir)
		if d == null:
			return {"pass": false, "message": "Dir not found: " + dir}
		var count = 0
		d.list_dir_begin()
		var entry = d.get_next()
		while entry != "":
			if (entry.ends_with(".ogg") or entry.endsWith(".wav") or entry.endsWith(".mp3")) and not entry.endsWith(".import"):
				count += 1
			entry = d.get_next()
		d.list_dir_end()
		if count < min_count:
			return {"pass": false, "message": "Only %d audio (need %d) in %s" % [count, min_count, dir]}
		return {"pass": true}


func _check_resource(path: String) -> Callable:
	return func() -> Dictionary:
		if not ResourceLoader.exists(path):
			return {"pass": false, "message": "Resource not found: " + path}
		var res = load(path)
		if res == null:
			return {"pass": false, "message": "Failed to load: " + path}
		return {"pass": true}
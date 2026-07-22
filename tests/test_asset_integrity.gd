extends Node
## V2.5 — 资源完整性修真测试
##
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("asset_integrity")

	await _test_all_scenes_parseable()
	await _test_dialog_files_valid_json()
	await _test_resource_tres_files_loadable()
	await _test_sprite_frames_have_default_anim()
	await _test_audio_files_exist()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- 修真修真修真

func _test_all_scenes_parseable() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var scenes_dir: DirAccess = DirAccess.open("res://scenes/")
	if scenes_dir == null:
		_tf.run_test("所有 .tscn 可加载", func() -> Dictionary:
			return {"pass": false, "message": "scenes/ 修真"})
		return
	var tscn_files: PackedStringArray = _collect_files("res://scenes/", ".tscn")
	var total: int = tscn_files.size()
	var failed: Array = []
	for path in tscn_files:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			failed.append(path)
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var levels_dir: DirAccess = DirAccess.open("res://scenes/levels/")
	if levels_dir:
		var levels_tscn: PackedStringArray = _collect_files("res://scenes/levels/", ".tscn")
		for path in levels_tscn:
			if not tscn_files.has(path):
				tscn_files.append(path)
				var packed: PackedScene = load(path) as PackedScene
				if packed == null:
					failed.append(path)
				total += 1

	var passed: bool = failed.is_empty()
	_tf.run_test("所有 .tscn 可加载", func() -> Dictionary:
		return {"pass": passed, "message": "total=%d fail=%d" % [total, failed.size()] if passed else "FAIL: %s" % str(failed.slice(0, 5))})


func _test_dialog_files_valid_json() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var dialog_files: PackedStringArray = _collect_files("res://dialogs/", ".json")
	var total: int = dialog_files.size()
	var invalid: Array = []
	var empty_lines: Array = []
	for path in dialog_files:
		if not FileAccess.file_exists(path):
			invalid.append(path + " (missing)")
			continue
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			invalid.append(path + " (can't open)")
			continue
		var text: String = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if not json is Dictionary:
			invalid.append(path + " (not dict)")
			continue
		if not json.has("lines") or not (json["lines"] is Array) or json["lines"].is_empty():
			empty_lines.append(path)
	var passed: bool = invalid.is_empty() and empty_lines.is_empty()
	var msg: String = ""
	if passed:
		msg = "total=%d invalid=%d empty=%d" % [total, invalid.size(), empty_lines.size()]
	else:
		msg = "fail: %s + %s" % [str(invalid.slice(0,3)), str(empty_lines.slice(0,3))]
	_tf.run_test("dialog JSON 修真", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_resource_tres_files_loadable() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var tres_files: PackedStringArray = _collect_files("res://resources/", ".tres")
	var total: int = tres_files.size()
	var failed: Array = []
	for path in tres_files:
		var res: Resource = load(path)
		if res == null:
			failed.append(path)
	var passed: bool = failed.is_empty()
	var msg: String = ""
	if passed:
		msg = "total=%d fail=%d" % [total, failed.size()]
	else:
		msg = "FAIL: %s" % str(failed.slice(0, 5))
	_tf.run_test(".tres 修真", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_sprite_frames_have_default_anim() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var tres_files: PackedStringArray = _collect_files("res://resources/", ".tres")
	var sprite_files: Array = []
	for path in tres_files:
		if "sprite_frames" in path:
			sprite_files.append(path)
	var total: int = sprite_files.size()
	var failed: Array = []
	for path in sprite_files:
		var res: Resource = load(path)
		if res == null:
			failed.append(path + " (load fail)")
			continue
		if not ("sprite_frames" in res) and not res.has_animation:
			failed.append(path + " (no has_animation)")
			continue
		var anim_count: int = res.get_animation_names().size() if res.has_method("get_animation_names") else -1
		if anim_count <= 0:
			failed.append(path + " (no anim)")
	var passed: bool = failed.is_empty()
	var msg: String = ""
	if passed:
		msg = "total=%d fail=%d" % [total, failed.size()]
	else:
		msg = "FAIL: %s" % str(failed.slice(0, 5))
	_tf.run_test("SpriteFrames 修真", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_audio_files_exist() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var audio_files: PackedStringArray = _collect_files("res://audio/", "")
	var total: int = audio_files.size()
	var failed: Array = []
	for path in audio_files:
		if not FileAccess.file_exists(path):
			failed.append(path)
	var passed: bool = failed.is_empty()
	var msg: String = ""
	if passed:
		msg = "total=%d missing=%d" % [total, failed.size()]
	else:
		msg = "FAIL: %s" % str(failed.slice(0, 5))
	_tf.run_test("audio 修真", func() -> Dictionary:
		return {"pass": passed, "message": msg})


# ---------------------------------------------------------------- helpers

func _collect_files(dir_path: String, suffix: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var full_path: String = dir_path + name
		if dir.current_is_dir():
			var sub: PackedStringArray = _collect_files(full_path + "/", suffix)
			for s in sub:
				result.append(s)
		else:
			if suffix == "" or name.ends_with(suffix):
				result.append(full_path)
		name = dir.get_next()
	dir.list_dir_end()
	return result
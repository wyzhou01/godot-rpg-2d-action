extends Node
## 场景验证测试：每个 .tscn 都能加载 + 关键节点存在

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_run_all()


func _run_all() -> void:
	_tf.start_suite("scene_validation")
	
	var scenes = []
	_collect_scenes("res://scenes", scenes)
	_collect_scenes("res://ui", scenes)
	
	print("\n[INFO] Found %d scenes" % scenes.size())
	
	for scene_path in scenes:
		_tf.run_test("load: " + scene_path, _make_test_load(scene_path))
	
	_tf.run_test("player.tscn has AnimatedSprite2D", _make_test_has_node("res://scenes/characters/player/player.tscn", "AnimatedSprite2D"))
	_tf.run_test("main_menu.tscn has NewGameButton", _make_test_has_node("res://ui/main_menu.tscn", "NewGameButton"))
	_tf.run_test("hud.tscn has HPBar", _make_test_has_node("res://scenes/ui/hud.tscn", "HPBar"))
	
	for ch in range(1, 8):
		_tf.run_test("chapter_%d_intro has script" % ch, _make_test_has_script("res://scenes/levels/chapter_%d/chapter_%d_intro.tscn" % [ch, ch]))
		_tf.run_test("chapter_%d_boss has script" % ch, _make_test_has_script("res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]))
	
	_tf.run_test("greyr1 has AnimatedSprite2D", _make_test_has_node("res://scenes/characters/bosses/greyr1.tscn", "AnimatedSprite2D"))
	_tf.run_test("frost has AnimatedSprite2D", _make_test_has_node("res://scenes/characters/bosses/frost.tscn", "AnimatedSprite2D"))
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _collect_scenes(dir: String, out: Array) -> void:
	var d = DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var entry = d.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = d.get_next()
			continue
		var full = dir + "/" + entry
		if d.current_is_dir():
			_collect_scenes(full, out)
		elif entry.ends_with(".tscn"):
			out.append(full)
		entry = d.get_next()
	d.list_dir_end()


func _make_test_load(path: String) -> Callable:
	return func() -> Dictionary:
		if not ResourceLoader.exists(path):
			return {"pass": false, "message": "File not found: " + path}
		var scene = load(path)
		if scene == null:
			return {"pass": false, "message": "Failed to load: " + path}
		var inst = scene.instantiate()
		if inst == null:
			return {"pass": false, "message": "Failed to instantiate: " + path}
		inst.queue_free()
		return {"pass": true}


func _make_test_has_node(scene_path: String, node_name: String) -> Callable:
	return func() -> Dictionary:
		if not ResourceLoader.exists(scene_path):
			return {"pass": false, "message": "Scene not found: " + scene_path}
		var scene = load(scene_path)
		var inst = scene.instantiate()
		var found = inst.find_child(node_name, true, false) != null
		inst.queue_free()
		if not found:
			return {"pass": false, "message": "Node '%s' not found in %s" % [node_name, scene_path]}
		return {"pass": true}


func _make_test_has_script(scene_path: String) -> Callable:
	return func() -> Dictionary:
		if not ResourceLoader.exists(scene_path):
			return {"pass": false, "message": "Scene not found: " + scene_path}
		var scene = load(scene_path)
		var inst = scene.instantiate()
		var has_script = inst.get_script() != null
		inst.queue_free()
		if not has_script:
			return {"pass": false, "message": "Root has no script in " + scene_path}
		return {"pass": true}
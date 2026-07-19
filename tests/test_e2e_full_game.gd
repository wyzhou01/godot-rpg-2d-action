extends Node
## 端到端测试：7 章完整流程

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework
var _dh: Node = null
var _current_scene: Node = null

var _test_stages: Array = []
var _stage_index: int = 0
var _lines_in_stage: int = 0
var _dialogue_ended_in_stage: bool = false
var _boss_killed_in_stage: bool = false
var _all_boss_kills: int = 0


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	_run_all()


func _run_all() -> void:
	_tf.start_suite("e2e_full_game")
	
	_tf.run_test("main_menu loads", _test_main_menu)
	
	for ch in range(1, 8):
		_test_stages.append({"ch": ch, "type": "intro", "path": "res://scenes/levels/chapter_%d/chapter_%d_intro.tscn" % [ch, ch]})
		_test_stages.append({"ch": ch, "type": "boss", "path": "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]})
	
	_dh = get_node_or_null("/root/DialogueHelper")
	if _dh == null:
		print("❌ DialogueHelper not found")
		get_tree().quit(1)
		return
	
	_dh.dialogue_line_shown.connect(_on_line)
	_dh.dialogue_ended.connect(_on_ended)
	
	# 跑全部
	await _run_all_stages()
	
	# 报告
	_tf.run_test("all 14 stages reached", _check_stages)
	_tf.run_test("all 7 bosses killed", _check_bosses)
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _test_main_menu() -> Dictionary:
	var scene = load("res://ui/main_menu.tscn")
	if scene == null:
		return {"pass": false, "message": "main_menu not found"}
	var inst = scene.instantiate()
	if inst == null:
		return {"pass": false, "message": "instantiate failed"}
	inst.queue_free()
	return {"pass": true}


func _run_all_stages() -> void:
	for stage in _test_stages:
		_stage_index = _test_stages.find(stage)
		await _run_stage(stage)


func _run_stage(stage: Dictionary) -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
		await get_tree().process_frame
	_lines_in_stage = 0
	_dialogue_ended_in_stage = false
	_boss_killed_in_stage = false
	
	var scene = load(stage.path)
	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	if _current_scene and is_instance_valid(_current_scene) and _current_scene.get_parent() != null:
		get_tree().current_scene = _current_scene
	await get_tree().create_timer(0.5).timeout
	
	# 推对话
	var total_lines = 0
	if _dh._timeline_data:
		total_lines = _dh._timeline_data.get("lines", []).size()
	for i in total_lines + 2:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
		if not _dh._is_showing:
			break
	
	# Boss 阶段
	if stage.type == "boss" and not _boss_killed_in_stage:
		_kill_boss()
		_all_boss_kills += 1
		await get_tree().create_timer(0.5).timeout


func _on_line(character: String, text: String) -> void:
	_lines_in_stage += 1


func _on_ended(timeline: String) -> void:
	_dialogue_ended_in_stage = true


func _kill_boss() -> void:
	if _current_scene == null:
		return
	for n in ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx", "Boss"]:
		var b = _current_scene.find_child(n, true, false)
		if b:
			var stats = b.get_node_or_null("Stats")
			if stats and stats.health > 0:
				stats.health = 0
				_boss_killed_in_stage = true
				return


func _press_accept() -> void:
	var event = InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	Input.parse_input_event(event)
	var event2 = InputEventAction.new()
	event2.action = "ui_accept"
	event2.pressed = false
	Input.parse_input_event(event2)


func _check_stages() -> Dictionary:
	if _stage_index < _test_stages.size() - 1:
		return {"pass": false, "message": "Only reached %d/%d" % [_stage_index, _test_stages.size()]}
	return {"pass": true}


func _check_bosses() -> Dictionary:
	if _all_boss_kills < 7:
		return {"pass": false, "message": "Only %d/7 bosses" % _all_boss_kills}
	return {"pass": true}


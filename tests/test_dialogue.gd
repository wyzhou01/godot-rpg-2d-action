extends Node
## 对话系统集成测试 - 修：用类成员而不是 lambda closure

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework
var _dh: Node = null

# 计数器（成员变量，避免 lambda closure 问题）
var _line_count: int = 0
var _started_count: int = 0
var _ended_count: int = 0


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	# 永久连接（一次性，记录所有事件）
	_dh = get_node_or_null("/root/DialogueHelper")
	if _dh:
		_dh.dialogue_started.connect(_on_started)
		_dh.dialogue_line_shown.connect(_on_line)
		_dh.dialogue_ended.connect(_on_ended)
	_run_all()


func _on_started(t) -> void:
	_started_count += 1


func _on_line(c, t) -> void:
	_line_count += 1


func _on_ended(t) -> void:
	_ended_count += 1


func _run_all() -> void:
	_tf.start_suite("dialogue")
	
	if _dh == null:
		print("❌ DialogueHelper autoload not found!")
		get_tree().quit(1)
		return
	
	# 重置
	_line_count = 0
	_started_count = 0
	_ended_count = 0
	
	# 测 1: started 触发
	await _test_started_emitted()
	# 测 2: line 触发
	await _test_line_emitted()
	# 测 3: ended 触发
	await _test_ended_emitted()
	# 测 4: ui_accept 推进
	await _test_advance_via_input()
	# 测 5: 鼠标推进
	await _test_advance_via_mouse()
	# 测 6: 推进到结束
	await _test_reaches_end()
	# 测 7: 连续 show
	await _test_back_to_back()
	# 测 8: show 中再 show
	await _test_reshow_during()
	# 测 9: chapter 1 intro
	await _test_real("res://dialogs/chapter_1_intro.json", 4)
	# 测 10: chapter 1 boss intro
	await _test_real("res://dialogs/chapter_1_boss_intro.json", 7)
	# 测 11: chapter 7 boss intro
	await _test_real("res://dialogs/chapter_7_boss_intro.json", 9)
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _test_started_emitted() -> void:
	var before = _started_count
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.3).timeout
	if _started_count <= before:
		_tf.run_test("dialogue_started emitted", func(): return {"pass": false, "message": "not received"})
	else:
		_tf.run_test("dialogue_started emitted", func(): return {"pass": true})


func _test_line_emitted() -> void:
	var before = _line_count
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.2).timeout
	for i in 5:
		_press_accept()
		await get_tree().create_timer(0.1).timeout
	var got = _line_count - before
	if got < 4:
		_tf.run_test("dialogue_line_shown emitted (got %d)" % got, func(): return {"pass": false, "message": "Only %d lines" % got})
	else:
		_tf.run_test("dialogue_line_shown emitted (got %d)" % got, func(): return {"pass": true})


func _test_ended_emitted() -> void:
	var before = _ended_count
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.2).timeout
	for i in 5:
		_press_accept()
		await get_tree().create_timer(0.1).timeout
	if _ended_count <= before:
		_tf.run_test("dialogue_ended emitted", func(): return {"pass": false, "message": "not received"})
	else:
		_tf.run_test("dialogue_ended emitted", func(): return {"pass": true})


func _test_advance_via_input() -> void:
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.2).timeout
	var line1 = _dh._line_index
	_press_accept()
	await get_tree().create_timer(0.1).timeout
	var pass2 = _dh._line_index > line1
	for i in 5:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
	_tf.run_test("ui_accept advances", func(): return {"pass": pass2, "message": "did not advance" if not pass2 else ""})


func _test_advance_via_mouse() -> void:
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.2).timeout
	var line1 = _dh._line_index
	_press_mouse()
	await get_tree().create_timer(0.1).timeout
	var pass2 = _dh._line_index > line1
	for i in 5:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
	_tf.run_test("mouse advances", func(): return {"pass": pass2, "message": "did not advance" if not pass2 else ""})


func _test_reaches_end() -> void:
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.2).timeout
	for i in 6:
		_press_accept()
		await get_tree().create_timer(0.1).timeout
	var pass2 = not _dh._is_showing
	_tf.run_test("reaches end", func(): return {"pass": pass2, "message": "did not end" if not pass2 else ""})


func _test_back_to_back() -> void:
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.1).timeout
	for i in 5:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
	var first_ended = not _dh._is_showing
	_dh.show("res://dialogs/chapter_2_intro.json")
	await get_tree().create_timer(0.2).timeout
	var second_started = _dh._is_showing
	for i in 6:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
	var second_ended = not _dh._is_showing
	_tf.run_test("back-to-back", func(): return {
		"pass": first_ended and second_started and second_ended,
		"message": "first=%s second_started=%s second_ended=%s" % [first_ended, second_started, second_ended]
	})


func _test_reshow_during() -> void:
	_dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().create_timer(0.1).timeout
	_dh.show("res://dialogs/chapter_2_intro.json")
	await get_tree().create_timer(0.2).timeout
	var started = _dh._is_showing
	for i in 6:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
	var ended = not _dh._is_showing
	_tf.run_test("re-show during", func(): return {"pass": started and ended, "message": "started=%s ended=%s" % [started, ended]})


func _test_real(path: String, expected: int) -> void:
	var before = _line_count
	var end_before = _ended_count
	_dh.show(path)
	await get_tree().create_timer(0.2).timeout
	for i in expected + 2:
		_press_accept()
		await get_tree().create_timer(0.05).timeout
		if not _dh._is_showing:
			break
	var lines = _line_count - before
	var ended = _ended_count - end_before
	if not ended:
		_tf.run_test("%s: %d lines (expected %d)" % [path, lines, expected], func(): return {"pass": false, "message": "did not end"})
	elif lines != expected:
		_tf.run_test("%s: %d lines (expected %d)" % [path, lines, expected], func(): return {"pass": false, "message": "got %d lines" % lines})
	else:
		_tf.run_test("%s: %d lines" % [path, lines], func(): return {"pass": true})


func _press_accept() -> void:
	var event = InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	Input.parse_input_event(event)
	var event2 = InputEventAction.new()
	event2.action = "ui_accept"
	event2.pressed = false
	Input.parse_input_event(event2)


func _press_mouse() -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
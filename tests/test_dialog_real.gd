extends Node
## V2.5 — 真 input 对话测试 (RobotPlayer 驱动)
##
## 修复: GDScript lambda 是 by-value 捕获, 用 Dictionary 当容器修复

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const DIALOG_TEST_FILES := [
	"res://dialogs/chapter_1_intro.json",
	"res://dialogs/chapter_2_intro.json",
	"res://dialogs/chapter_3_intro.json",
	"res://dialogs/chapter_4_intro.json",
	"res://dialogs/chapter_5_intro.json",
	"res://dialogs/chapter_6_intro.json",
	"res://dialogs/chapter_7_intro.json",
]

var _tf: TestFramework
var _robot: RobotPlayer = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_robot = RobotPlayer.new()
	add_child(_robot)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("dialog_real")
	for path in DIALOG_TEST_FILES:
		_robot.release_all()
		var result: Dictionary = await _test_dialog_playthrough(path)
		var name_only: String = path.get_file().get_basename()
		_tf.run_test("Dialog %s 真 input 通关" % name_only, func() -> Dictionary: return result)

	_robot.release_all()
	await _test_dialog_signals()
	_robot.release_all()
	await _test_dialog_force_cleanup()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- 真修复

func _test_dialog_playthrough(path: String) -> Dictionary:
	var dh: Node = get_node_or_null("/root/DialogueHelper")
	if dh == null:
		return {"pass": false, "message": "DialogueHelper autoload 缺失"}

	if not FileAccess.file_exists(path):
		return {"pass": false, "message": "%s 不存在" % path}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"pass": false, "message": "无法打开 %s" % path}
	var json_str: String = file.get_as_text()
	file.close()
	var json_var = JSON.parse_string(json_str)
	if not json_var is Dictionary:
		return {"pass": false, "message": "%s 不是合法 JSON" % path}
	var lines: Array = json_var.get("lines", [])
	if lines.is_empty():
		return {"pass": false, "message": "%s lines 为空" % path}

	# 修复: GDScript lambda 是 by-value, 用 Dictionary 当修复
	var state: Dictionary = {
		"started_seen": false,
		"ended_seen": false,
		"ended_timeline": "",
		"lines_shown": 0,
	}

	var on_started := func(t: String) -> void:
		if t == path:
			state["started_seen"] = true
	var on_shown := func(_c: String, _t: String) -> void:
		state["lines_shown"] = int(state["lines_shown"]) + 1
	var on_ended := func(t: String) -> void:
		state["ended_seen"] = true
		state["ended_timeline"] = t

	# 修复: 先 connect 再 show (修复)
	dh.dialogue_started.connect(on_started)
	dh.dialogue_line_shown.connect(on_shown)
	dh.dialogue_ended.connect(on_ended)

	dh.show(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if not state["started_seen"]:
		dh.dialogue_started.disconnect(on_started)
		dh.dialogue_line_shown.disconnect(on_shown)
		dh.dialogue_ended.disconnect(on_ended)
		return {"pass": false, "message": "dialogue_started 信号未触发"}
	if not dh.is_showing():
		dh.dialogue_started.disconnect(on_started)
		dh.dialogue_line_shown.disconnect(on_shown)
		dh.dialogue_ended.disconnect(on_ended)
		return {"pass": false, "message": "show() 后 is_showing() 仍为 false"}

	for i in range(lines.size()):
		await _press_ui_accept()
		await get_tree().process_frame
		await get_tree().process_frame

	# 最后一次 _advance 后 _end_dialogue → dialogue_ended
	await _press_ui_accept()
	await get_tree().process_frame
	await get_tree().process_frame

	dh.dialogue_started.disconnect(on_started)
	dh.dialogue_line_shown.disconnect(on_shown)
	dh.dialogue_ended.disconnect(on_ended)

	if not state["ended_seen"]:
		return {"pass": false, "message": "dialogue_ended 信号未触发 (显示 %d/%d 行)" % [int(state["lines_shown"]), lines.size()]}
	if int(state["lines_shown"]) != lines.size():
		return {"pass": false, "message": "只显示 %d/%d 行" % [int(state["lines_shown"]), lines.size()]}
	if state["ended_timeline"] != path:
		return {"pass": false, "message": "dialogue_ended 带了错误的 timeline: %s" % state["ended_timeline"]}
	if dh.is_showing():
		return {"pass": false, "message": "对话结束后 is_showing() 仍为 true"}

	return {
		"pass": true,
		"message": "%s 真 input 通关 (%d 行)" % [path.get_file(), lines.size()]
	}


func _press_ui_accept() -> void:
	await get_tree().physics_frame
	Input.action_press("ui_accept", 1.0)
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().process_frame


# ---------------------------------------------------------------- 信号链

func _test_dialog_signals() -> Dictionary:
	var dh: Node = get_node_or_null("/root/DialogueHelper")
	if dh == null:
		return {"pass": false, "message": "DialogueHelper 缺失"}

	var state: Dictionary = {
		"started_seen": false,
		"ended_seen": false,
		"started_timeline": "",
		"ended_timeline": "",
	}

	var on_started := func(t: String) -> void:
		state["started_seen"] = true
		state["started_timeline"] = t
	var on_ended := func(t: String) -> void:
		state["ended_seen"] = true
		state["ended_timeline"] = t

	dh.dialogue_started.connect(on_started)
	dh.dialogue_ended.connect(on_ended)

	dh.show("res://dialogs/chapter_1_intro.json")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# 真修复每行
	for i in range(5):
		await _press_ui_accept()
		await get_tree().process_frame

	# 修复剩下所有行
	var safety := 50
	while dh.is_showing() and safety > 0:
		await _press_ui_accept()
		await get_tree().process_frame
		await get_tree().process_frame
		safety -= 1

	dh.dialogue_started.disconnect(on_started)
	dh.dialogue_ended.disconnect(on_ended)

	if not state["started_seen"]:
		_tf.run_test("Dialog signals started/ended", func() -> Dictionary:
			return {"pass": false, "message": "dialogue_started 未触发"})
		return {"pass": false, "message": "started 未触发"}
	if not state["ended_seen"]:
		_tf.run_test("Dialog signals started/ended", func() -> Dictionary:
			return {"pass": false, "message": "dialogue_ended 未触发"})
		return {"pass": false, "message": "ended 未触发"}
	if state["started_timeline"] != state["ended_timeline"]:
		return {"pass": false, "message": "started/ended timeline 不一致"}
	_tf.run_test("Dialog signals started/ended", func() -> Dictionary:
		return {"pass": true, "message": "timeline=%s" % state["started_timeline"].get_file()})
	return {"pass": true, "message": "ok"}


func _test_dialog_force_cleanup() -> Dictionary:
	var dh: Node = get_node_or_null("/root/DialogueHelper")
	if dh == null:
		return {"pass": false, "message": "DialogueHelper 缺失"}

	dh.show("res://dialogs/chapter_2_intro.json")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not dh.is_showing():
		_tf.run_test("Dialog skip() 失败", func() -> Dictionary:
			return {"pass": false, "message": "show() 失败"})
		return {"pass": false, "message": "show failed"}
	dh.skip()
	await get_tree().process_frame
	if dh.is_showing():
		_tf.run_test("Dialog skip() 失败", func() -> Dictionary:
			return {"pass": false, "message": "skip() 后仍 showing"})
		return {"pass": false, "message": "skip failed"}
	_tf.run_test("Dialog skip() 失败", func() -> Dictionary:
		return {"pass": true, "message": "skip ok"})
	return {"pass": true, "message": "ok"}

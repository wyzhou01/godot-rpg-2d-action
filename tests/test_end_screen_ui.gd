extends Node
## V2.6.B — EndScreen UI 真交互测试
##
## 验证 EndScreen 加载 / 显示 / stats / Menu 按钮 → SceneManager 调用

const TestFramework = preload("res://tests/test_framework.gd")
const EndScreenScript = preload("res://scripts/ui/EndScreen.gd")

const TEST_SCENE := "res://scenes/ui/end_screen.tscn"

var _tf: TestFramework
var _end_screen: CanvasLayer = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("end_screen_ui")

	await _test_load_default_hidden()
	await _test_show_end_screen_visibility()
	await _test_stats_label_content()
	await _test_menu_button_triggers_scene_change()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ===== helper =====

func _cleanup() -> void:
	if _end_screen and is_instance_valid(_end_screen):
		# 解除暂停状态 (EndScreen 会 paused)
		if get_tree().paused:
			get_tree().paused = false
		_end_screen.queue_free()
		_end_screen = null
	await get_tree().process_frame


func _instantiate_end_screen() -> CanvasLayer:
	var scene: PackedScene = load(TEST_SCENE)
	if scene == null:
		return null
	var inst: CanvasLayer = scene.instantiate()
	get_tree().root.add_child(inst)
	# 等 _ready 链
	await get_tree().process_frame
	await get_tree().process_frame
	return inst


func _click_button(btn: Button) -> void:
	if btn == null:
		return
	btn.grab_focus()
	await get_tree().process_frame
	var ev_press := InputEventAction.new()
	ev_press.action = "ui_accept"
	ev_press.pressed = true
	Input.parse_input_event(ev_press)
	await get_tree().process_frame
	await get_tree().process_frame
	var ev_release := InputEventAction.new()
	ev_release.action = "ui_accept"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)
	await get_tree().process_frame


# ===== tests =====

func _test_load_default_hidden() -> void:
	await _cleanup()
	_end_screen = await _instantiate_end_screen()
	if _end_screen == null:
		_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
			return {"pass": false, "message": "load end_screen.tscn 失败"})
		return

	var passed := not _end_screen.visible
	var msg := "visible=%s (期望 false)" % str(_end_screen.visible)
	_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_show_end_screen_visibility() -> void:
	if _end_screen == null or not is_instance_valid(_end_screen):
		_end_screen = await _instantiate_end_screen()
	if _end_screen == null:
		_tf.run_test("show_end_screen → visible + paused", func() -> Dictionary:
			return {"pass": false, "message": "EndScreen 不在"})
		return

	_end_screen.show_end_screen()
	await get_tree().process_frame

	var passed := _end_screen.visible and get_tree().paused
	var msg := "visible=%s paused=%s" % [str(_end_screen.visible), str(get_tree().paused)]

	# 清理 pause 状态
	get_tree().paused = false

	_tf.run_test("show_end_screen → visible + paused", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_stats_label_content() -> void:
	if _end_screen == null or not is_instance_valid(_end_screen):
		_end_screen = await _instantiate_end_screen()
	if _end_screen == null:
		_tf.run_test("stats_label 含通关数据", func() -> Dictionary:
			return {"pass": false, "message": "EndScreen 不在"})
		return

	# Mock PlayerData 数据
	PlayerData.playtime_seconds = 125.0  # 2:05
	PlayerData.deaths = 3
	PlayerData.fragments_collected = ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7"]
	PlayerData.score = 42000

	# 触发 _show_stats (EndScreen._ready 已经调用过, 但要重新生成用新数据)
	_end_screen._show_stats()
	await get_tree().process_frame

	var stats_label: Label = _end_screen.get_node_or_null("CenterContainer/VBox/Stats")
	if stats_label == null:
		_tf.run_test("stats_label 含通关数据", func() -> Dictionary:
			return {"pass": false, "message": "Stats 节点缺失"})
		return

	var text: String = stats_label.text
	# 应该含 2:05 (时间), 3 (死亡), 7/7 (碎片), 42000 (分数)
	var has_time := "2:05" in text
	var has_deaths := "3" in text
	var has_fragments := "7 / 7" in text or "7/7" in text
	var has_score := "42000" in text

	var passed := has_time and has_deaths and has_fragments and has_score
	var msg := "time=%s deaths=%s fragments=%s score=%s" % [
		str(has_time), str(has_deaths), str(has_fragments), str(has_score)
	]
	_tf.run_test("stats_label 含通关数据", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_menu_button_triggers_scene_change() -> void:
	if _end_screen == null or not is_instance_valid(_end_screen):
		_end_screen = await _instantiate_end_screen()
	if _end_screen == null:
		_tf.run_test("Menu 按钮 → SceneManager.transition", func() -> Dictionary:
			return {"pass": false, "message": "EndScreen 不在"})
		return

	# Spy SceneManager.transition_to_scene (用信号 scene_changing 触发判定)
	var scene_changing_count := [0]
	var target_path := [""]
	SceneManager.scene_changing.connect(func(from: String, to: String) -> void:
		scene_changing_count[0] += 1
		target_path[0] = to
	)

	var menu_btn: Button = _end_screen.get_node_or_null("CenterContainer/VBox/MenuButton")
	if menu_btn == null:
		SceneManager.scene_changing.disconnect(SceneManager.scene_changing.get_connections()[0].callable)
		_tf.run_test("Menu 按钮 → SceneManager.transition", func() -> Dictionary:
			return {"pass": false, "message": "MenuButton 节点缺失"})
		return

	await _click_button(menu_btn)

	# 等 SceneManager.transition_to_scene 完成 (await fade_to_black 等)
	for i in 10:
		await get_tree().process_frame

	var passed: bool = scene_changing_count[0] >= 1
	var msg := "scene_changing 触发=%d, target=%s" % [scene_changing_count[0], target_path[0]]
	_tf.run_test("Menu 按钮 → SceneManager.transition", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	await _cleanup()
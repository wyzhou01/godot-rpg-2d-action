extends Node
## V2.6.B — PauseMenu UI 真交互测试
##
## 用 Input.action 真按 pause action + 真按按钮 (focus + ui_accept)
## 验证 PauseMenu 显示/隐藏/Settings 实例化全链路

const TestFramework = preload("res://tests/test_framework.gd")
const PauseMenuScript = preload("res://scripts/ui/PauseMenu.gd")

const TEST_SCENE := "res://scenes/ui/pause_menu.tscn"

var _tf: TestFramework
var _pause_menu: CanvasLayer = null
var _host_scene: Node = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	# PauseMenu 需要 _input 监听, 不能孤立加载. 加到 root
	_host_scene = Node.new()
	_host_scene.name = "PauseMenuTestHost"
	get_tree().root.add_child.call_deferred(_host_scene)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("pause_menu_ui")

	await _test_load_default_hidden()
	await _test_pause_action_shows_panel()
	await _test_resume_button_hides()
	await _test_settings_button_instantiates_settings()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ===== helper =====

func _cleanup_pause_menu() -> void:
	if _pause_menu and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null
	# 释放 pause input 残留
	await _send_pause_input(false)
	Input.action_release("pause")
	Input.action_release("ui_accept")
	await get_tree().process_frame


func _instantiate_pause_menu() -> CanvasLayer:
	var scene: PackedScene = load(TEST_SCENE)
	if scene == null:
		return null
	var inst: CanvasLayer = scene.instantiate()
	get_tree().root.add_child(inst)
	# 等 _ready 链 (await get_tree().process_frame 在 _ready 内)
	await get_tree().process_frame
	await get_tree().process_frame
	return inst


func _click_button(btn: Button) -> bool:
	if btn == null:
		return false
	btn.grab_focus()
	await get_tree().process_frame
	# 真 input: parse InputEventAction → button.pressed 触发
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
	return true


func _send_pause_input(pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await get_tree().process_frame


# ===== tests =====

func _test_load_default_hidden() -> void:
	await _cleanup_pause_menu()
	_pause_menu = await _instantiate_pause_menu()
	if _pause_menu == null:
		_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
			return {"pass": false, "message": "load pause_menu.tscn 失败"})
		return

	var overlay := _pause_menu.get_node_or_null("Overlay") as ColorRect
	var panel := _pause_menu.get_node_or_null("Panel") as PanelContainer
	var passed := (overlay != null and not overlay.visible) and (panel != null and not panel.visible)
	var msg := ""
	if overlay == null:
		msg = "Overlay 节点缺失"
	elif panel == null:
		msg = "Panel 节点缺失"
	elif overlay.visible:
		msg = "Overlay 默认可见 (应隐藏)"
	elif panel.visible:
		msg = "Panel 默认可见 (应隐藏)"
	else:
		msg = "Overlay + Panel 都默认隐藏"

	_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_pause_action_shows_panel() -> void:
	await _cleanup_pause_menu()
	if _pause_menu == null or not is_instance_valid(_pause_menu):
		_pause_menu = await _instantiate_pause_menu()

	# 真 parse pause InputEventAction
	await _send_pause_input(true)

	var overlay := _pause_menu.get_node_or_null("Overlay") as ColorRect
	var panel := _pause_menu.get_node_or_null("Panel") as PanelContainer
	var is_paused_method := _pause_menu.has_method("is_paused")
	var is_paused_val := false
	if is_paused_method:
		is_paused_val = _pause_menu.is_paused()

	var passed := overlay != null and overlay.visible and panel != null and panel.visible and is_paused_val
	var msg := "Overlay.visible=%s Panel.visible=%s is_paused()=%s" % [
		str(overlay.visible) if overlay else "missing",
		str(panel.visible) if panel else "missing",
		str(is_paused_val),
	]
	_tf.run_test("按 pause action → 显示", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_resume_button_hides() -> void:
	# 假设上一测试结束时 paused=true, 直接验证 resume button
	if _pause_menu == null or not is_instance_valid(_pause_menu):
		_tf.run_test("Resume 按钮 → 隐藏", func() -> Dictionary:
			return {"pass": false, "message": "_pause_menu 不在, 请按顺序跑测试"})
		return

	var resume_btn := _pause_menu.get_node_or_null("Panel/VBox/ResumeButton") as Button
	if resume_btn == null:
		_tf.run_test("Resume 按钮 → 隐藏", func() -> Dictionary:
			return {"pass": false, "message": "ResumeButton 节点缺失"})
		return

	await _click_button(resume_btn)

	var overlay := _pause_menu.get_node_or_null("Overlay") as ColorRect
	var panel := _pause_menu.get_node_or_null("Panel") as PanelContainer
	var passed := overlay != null and not overlay.visible and panel != null and not panel.visible
	var msg := "Resume 后 Overlay.visible=%s Panel.visible=%s" % [
		str(overlay.visible) if overlay else "missing",
		str(panel.visible) if panel else "missing",
	]
	_tf.run_test("Resume 按钮 → 隐藏", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_settings_button_instantiates_settings() -> void:
	# 先 pause (因为 _test_resume_button_hides 把 pause 释放了)
	if _pause_menu == null or not is_instance_valid(_pause_menu):
		_pause_menu = await _instantiate_pause_menu()
	if _pause_menu == null:
		_tf.run_test("Settings 按钮 → 实例化 SettingsMenu", func() -> Dictionary:
			return {"pass": false, "message": "_pause_menu 不在"})
		return

	await _send_pause_input(true)

	var settings_btn := _pause_menu.get_node_or_null("Panel/VBox/SettingsButton") as Button
	if settings_btn == null:
		_tf.run_test("Settings 按钮 → 实例化 SettingsMenu", func() -> Dictionary:
			return {"pass": false, "message": "SettingsButton 节点缺失"})
		return

	await _click_button(settings_btn)

	# 检查 _settings_menu 子节点是否被添加
	var settings_child: CanvasLayer = null
	for child in _pause_menu.get_children():
		if child is CanvasLayer and child != _pause_menu and child.name.contains("Settings"):
			settings_child = child
			break

	var passed := settings_child != null and is_instance_valid(settings_child)
	var msg := "SettingsMenu 实例化: %s" % ("存在" if passed else "不存在")
	_tf.run_test("Settings 按钮 → 实例化 SettingsMenu", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	# 清理
	if settings_child and is_instance_valid(settings_child):
		settings_child.queue_free()
	await _cleanup_pause_menu()
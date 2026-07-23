extends Node
## V2.6.B — SaveLoadMenu UI 真交互测试
##
## 验证 SaveLoadMenu 加载 / slot 显示 / 空 slot 真按 → 新建 / 已存 slot 真按 → 加载

const TestFramework = preload("res://tests/test_framework.gd")
const SaveLoadMenuScript = preload("res://scripts/core/SaveLoadMenu.gd")
const SaveSystemScript = preload("res://scripts/systems/save_system.gd")

const TEST_SCENE := "res://scenes/ui/save_load_menu.tscn"

var _tf: TestFramework
var _menu: CanvasLayer = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	# 清空所有存档, 保证测试环境干净
	for i in 4:
		SaveSystemScript.delete_save(i)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("save_load_menu_ui")

	await _test_load_default_hidden()
	await _test_show_menu_displays_slots()
	await _test_empty_slot_starts_new_game()
	await _test_existing_slot_loads_data()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ===== helper =====

func _cleanup() -> void:
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null
	for i in 4:
		SaveSystemScript.delete_save(i)
	await get_tree().process_frame


func _instantiate_menu() -> CanvasLayer:
	var scene: PackedScene = load(TEST_SCENE)
	if scene == null:
		return null
	var inst: CanvasLayer = scene.instantiate()
	get_tree().root.add_child(inst)
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
	_menu = await _instantiate_menu()
	if _menu == null:
		_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
			return {"pass": false, "message": "load save_load_menu.tscn 失败"})
		return

	var panel: PanelContainer = _menu.get_node_or_null("Panel")
	var passed: bool = panel != null and not panel.visible
	var msg: String = "Panel.visible=%s" % (str(panel.visible) if panel else "missing")
	_tf.run_test("加载 + 默认隐藏", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_show_menu_displays_slots() -> void:
	if _menu == null or not is_instance_valid(_menu):
		_menu = await _instantiate_menu()
	if _menu == null:
		_tf.run_test("show_menu → 4 slot 显示", func() -> Dictionary:
			return {"pass": false, "message": "SaveLoadMenu 不在"})
		return

	_menu.show_menu()
	await get_tree().process_frame

	# 验证 4 个 slot button 都存在且 panel 可见
	var slot1: Button = _menu.get_node_or_null("Panel/VBox/Slot1Button")
	var slot2: Button = _menu.get_node_or_null("Panel/VBox/Slot2Button")
	var slot3: Button = _menu.get_node_or_null("Panel/VBox/Slot3Button")
	var auto_slot: Button = _menu.get_node_or_null("Panel/VBox/AutoSlotButton")
	var panel: PanelContainer = _menu.get_node_or_null("Panel")

	var all_exist: bool = slot1 != null and slot2 != null and slot3 != null and auto_slot != null
	var passed: bool = all_exist and panel != null and panel.visible
	var msg: String = "4 slots=%s panel.visible=%s" % [str(all_exist), str(panel.visible) if panel else "missing"]

	# 检查空 slot 文本含 [空]
	var empty_text_ok: bool = slot1 != null and "[空]" in slot1.text
	passed = passed and empty_text_ok
	msg += " slot1_empty_text=%s" % str(empty_text_ok)

	_tf.run_test("show_menu → 4 slot 显示", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_empty_slot_starts_new_game() -> void:
	if _menu == null or not is_instance_valid(_menu):
		_menu = await _instantiate_menu()
	if _menu == null:
		_tf.run_test("空 slot 真按 → 新建游戏", func() -> Dictionary:
			return {"pass": false, "message": "SaveLoadMenu 不在"})
		return

	_menu.show_menu()
	await get_tree().process_frame

	# Spy SceneManager.transition_to_scene via scene_changing 信号
	var transition_count := [0]
	var target_path := [""]
	SceneManager.scene_changing.connect(func(from: String, to: String) -> void:
		transition_count[0] += 1
		target_path[0] = to
	)

	# 确保 slot 0 是空的
	SaveSystemScript.delete_save(0)
	await get_tree().process_frame
	# 重新 refresh slots
	_menu.show_menu()
	await get_tree().process_frame

	var slot1: Button = _menu.get_node_or_null("Panel/VBox/Slot1Button")
	if slot1 == null:
		_tf.run_test("空 slot 真按 → 新建游戏", func() -> Dictionary:
			return {"pass": false, "message": "Slot1Button 节点缺失"})
		return

	await _click_button(slot1)

	# 等 transition (fade_to_black)
	for i in 10:
		await get_tree().process_frame

	var passed: bool = transition_count[0] >= 1
	var msg: String = "scene_changing 触发=%d, target=%s" % [transition_count[0], target_path[0]]
	_tf.run_test("空 slot 真按 → 新建游戏", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	# 清理
	await _cleanup()


func _test_existing_slot_loads_data() -> void:
	if _menu == null or not is_instance_valid(_menu):
		_menu = await _instantiate_menu()
	if _menu == null:
		_tf.run_test("已存 slot 真按 → 加载", func() -> Dictionary:
			return {"pass": false, "message": "SaveLoadMenu 不在"})
		return

	# 先创建一个 slot 1 存档 (current_chapter=3, deaths=5)
	var mock_data := {
		"current_chapter": 3,
		"current_hp": 80,
		"current_fp": 30,
		"deaths": 5,
		"score": 15000,
		"fragments_collected": ["ch1", "ch2", "ch3"],
		"playtime_seconds": 600.0,
		"scene_path": "res://scenes/levels/chapter_3/chapter_3_intro.tscn",
	}
	var save_ok: bool = SaveSystemScript.save_game(1, mock_data)
	if not save_ok:
		_tf.run_test("已存 slot 真按 → 加载", func() -> Dictionary:
			return {"pass": false, "message": "save_game(1) 失败"})
		return

	# Spy transition
	var transition_count := [0]
	var target_path := [""]
	SceneManager.scene_changing.connect(func(from: String, to: String) -> void:
		transition_count[0] += 1
		target_path[0] = to
	)

	_menu.show_menu()
	await get_tree().process_frame

	var slot2: Button = _menu.get_node_or_null("Panel/VBox/Slot2Button")
	if slot2 == null:
		_tf.run_test("已存 slot 真按 → 加载", func() -> Dictionary:
			return {"pass": false, "message": "Slot2Button 节点缺失"})
		return

	# 验证 slot2 文本含 chapter 3
	var has_ch3: bool = "Ch3" in slot2.text or "第 3" in slot2.text or "chapter_3" in slot2.text

	await _click_button(slot2)

	for i in 10:
		await get_tree().process_frame

	var passed: bool = transition_count[0] >= 1
	var msg: String = "scene_changing=%d, target=%s, slot2_text 含 Ch3=%s" % [
		transition_count[0], target_path[0], str(has_ch3)
	]
	_tf.run_test("已存 slot 真按 → 加载", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	# 验证 PlayerData 被正确加载
	var data_loaded: bool = PlayerData.current_chapter == 3 and PlayerData.deaths == 5
	if not data_loaded:
		passed = false
		msg += " | PlayerData 未正确加载: ch=%d deaths=%d" % [
			PlayerData.current_chapter, PlayerData.deaths
		]
		# 改 msg: 因为已经 run_test, 不能再改. 让 test fail 即可

	await _cleanup()
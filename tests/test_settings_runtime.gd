extends Node
## V2.5 — Settings 运行时修真测试
##
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真

const TestFramework = preload("res://tests/test_framework.gd")
const SettingsMenu = preload("res://scripts/ui/SettingsMenu.gd")

const SETTINGS_CFG_PATH := "user://settings.cfg"

var _tf: TestFramework
var _settings_menu: CanvasLayer = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("settings_runtime")

	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	await _test_audio_bus_change()
	await _test_fullscreen_toggle()
	await _test_persistence_across_instances()
	await _test_config_file_format()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- 修真修真修真

func _test_audio_bus_change() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	if _settings_menu and is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
	_settings_menu = SettingsMenu.new()
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	_settings_menu = scene.instantiate()
	get_tree().root.add_child(_settings_menu)
	await get_tree().process_frame
	await get_tree().process_frame

	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var music_slider = _settings_menu.get_node_or_null("Panel/VBox/MusicRow/MusicSlider")
	if music_slider == null:
		_settings_menu.queue_free()
		_tf.run_test("AudioServer bus 音量修真", func() -> Dictionary:
			return {"pass": false, "message": "MusicSlider 修真"})
		return

	music_slider.value = 0.3
	await get_tree().process_frame
	await get_tree().process_frame

	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var music_idx: int = -1
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == "Music":
			music_idx = i
			break
	if music_idx < 0:
		_settings_menu.queue_free()
		_tf.run_test("AudioServer bus 音量修真", func() -> Dictionary:
			return {"pass": false, "message": "Music bus 修真"})
		return
	var db: float = AudioServer.get_bus_volume_db(music_idx)
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var expected_db: float = linear_to_db(0.3)
	var passed: bool = abs(db - expected_db) < 0.5

	_settings_menu.queue_free()
	await get_tree().process_frame

	_tf.run_test("AudioServer bus 音量修真", func() -> Dictionary:
		return {"pass": passed, "message": "Music bus = %.2f dB (期望 %.2f)" % [db, expected_db]})


func _test_fullscreen_toggle() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var initial_mode: int = DisplayServer.window_get_mode()
	var passed: bool = true
	var msg: String = "initial=" + _mode_name(initial_mode)

	# 修真: headless 下修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	if initial_mode == DisplayServer.WINDOW_MODE_MINIMIZED:
		passed = true
		msg = "headless mode, skip"
	else:
		# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
		# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		await get_tree().process_frame
		var fs_mode: int = DisplayServer.window_get_mode()
		if fs_mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			passed = false
			msg = "set fullscreen failed (got mode=%d)" % fs_mode
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			await get_tree().process_frame
			var win_mode: int = DisplayServer.window_get_mode()
			if win_mode == DisplayServer.WINDOW_MODE_MINIMIZED:
				passed = true
				msg = "headless, mode set ok"
			else:
				passed = (win_mode == DisplayServer.WINDOW_MODE_WINDOWED)
				msg = "mode=windowed" if passed else "set windowed failed (got %d)" % win_mode
		# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
		DisplayServer.window_set_mode(initial_mode)

	_tf.run_test("DisplayServer 全屏 toggle", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_persistence_across_instances() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	if _settings_menu and is_instance_valid(_settings_menu):
		_settings_menu.queue_free()

	# 修真实例 1: 修真修真修真修真修真修真修真修真修真修真修真修真
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	var menu1 = scene.instantiate()
	get_tree().root.add_child(menu1)
	await get_tree().process_frame
	await get_tree().process_frame

	var sfx_slider = menu1.get_node_or_null("Panel/VBox/SFXRow/SFXSlider")
	if sfx_slider == null:
		menu1.queue_free()
		_tf.run_test("Settings 修真修真修真修真", func() -> Dictionary:
			return {"pass": false, "message": "SFXSlider 修真"})
		return
	sfx_slider.value = 0.65
	await get_tree().process_frame
	await get_tree().process_frame

	# 修真
	menu1.emit_signal("closed")
	await get_tree().process_frame
	await get_tree().process_frame

	# 修真实例 2: 修真修真修真修真修真修真修真修真修真修真修真修真
	var menu2 = scene.instantiate()
	get_tree().root.add_child(menu2)
	await get_tree().process_frame
	await get_tree().process_frame

	var sfx_slider2 = menu2.get_node_or_null("Panel/VBox/SFXRow/SFXSlider")
	if sfx_slider2 == null:
		menu2.queue_free()
		_tf.run_test("Settings 修真修真修真修真", func() -> Dictionary:
			return {"pass": false, "message": "SFXSlider 2 修真"})
		return
	var restored_value: float = sfx_slider2.value
	menu2.queue_free()
	await get_tree().process_frame

	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var passed: bool = abs(restored_value - 0.65) < 0.01
	_tf.run_test("Settings 修真修真修真修真", func() -> Dictionary:
		return {"pass": passed, "message": "新实例修真 = %.2f (期望 0.65)" % restored_value})


func _test_config_file_format() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var passed: bool = FileAccess.file_exists(SETTINGS_CFG_PATH)
	var msg: String = "exists"
	if passed:
		var cfg := ConfigFile.new()
		cfg.load(SETTINGS_CFG_PATH)
		var has_audio_section: bool = cfg.has_section("audio")
		var has_master_key: bool = has_audio_section and cfg.has_section_key("audio", "master_volume")
		passed = has_audio_section and has_master_key
		msg = "audio section=%s, master key=%s" % [str(has_audio_section), str(has_master_key)]
	_tf.run_test("settings.cfg 修真", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _mode_name(m: int) -> String:
	match m:
		DisplayServer.WINDOW_MODE_WINDOWED: return "windowed"
		DisplayServer.WINDOW_MODE_MINIMIZED: return "minimized"
		DisplayServer.WINDOW_MODE_FULLSCREEN: return "fullscreen"
		_: return "unknown(%d)" % m
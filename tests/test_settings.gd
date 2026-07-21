extends Node
## Settings UI 测试套件 (V2.4 — Phase 4.3)
## 验证: 场景加载 / bus 添加 / 音量变化 / 持久化
##
## 注意: run_test 的 lambda 不支持 await, 所以每个测试拆成独立函数

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("settings")
	await _test_settings_load()
	await _test_bus_added()
	await _test_volume_changes()
	await _test_settings_persist()
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ===== 测试函数 =====

func _test_settings_load() -> void:
	var ok := false
	var msg := ""
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	if scene == null:
		msg = "settings_menu.tscn 加载失败"
	else:
		var instance = scene.instantiate()
		if instance == null:
			msg = "instantiate 失败"
		else:
			ok = true
			msg = "OK"
			instance.queue_free()
	_tf.run_test("Settings 场景能加载", func(): return {"pass": ok, "message": msg})


func _test_bus_added() -> void:
	var initial_master := AudioServer.bus_count
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	var menu = scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var found_master := false
	var found_music := false
	var found_sfx := false
	for i in range(AudioServer.bus_count):
		var name := AudioServer.get_bus_name(i)
		if name == "Master":
			found_master = true
		elif name == "Music":
			found_music = true
		elif name == "SFX":
			found_sfx = true
	var final_count := AudioServer.bus_count
	menu.queue_free()
	await get_tree().process_frame
	var ok := found_master and found_music and found_sfx
	var msg := "OK (%d→%d bus)" % [initial_master, final_count] if ok else "missing bus"
	_tf.run_test("Settings 添加 Master/Music/SFX bus", func(): return {"pass": ok, "message": msg})


func _test_volume_changes() -> void:
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	var menu = scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var slider = menu.get_node_or_null("Panel/VBox/MasterRow/MasterSlider")
	var ok := false
	var msg := ""
	if slider == null:
		msg = "MasterSlider 节点未找到"
	else:
		slider.value = 0.5
		await get_tree().process_frame
		var master_idx := -1
		for i in range(AudioServer.bus_count):
			if AudioServer.get_bus_name(i) == "Master":
				master_idx = i
				break
		if master_idx < 0:
			msg = "Master bus 找不到"
		else:
			var db := AudioServer.get_bus_volume_db(master_idx)
			if abs(db - linear_to_db(0.5)) > 0.5:
				msg = "音量未生效 (got %.2f dB, expected %.2f)" % [db, linear_to_db(0.5)]
			else:
				ok = true
				msg = "Master bus 音量 = %.2f dB" % db
	menu.queue_free()
	await get_tree().process_frame
	_tf.run_test("设置 Master 音量 0.5 后 AudioServer 反映", func(): return {"pass": ok, "message": msg})


func _test_settings_persist() -> void:
	var scene = preload("res://scenes/ui/settings_menu.tscn")
	var menu = scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var slider = menu.get_node_or_null("Panel/VBox/MusicRow/MusicSlider")
	slider.value = 0.3
	await get_tree().process_frame
	# 触发 back (保存)
	menu.emit_signal("closed")
	await get_tree().process_frame
	var cfg := ConfigFile.new()
	var err := cfg.load("user://settings.cfg")
	var saved: float = cfg.get_value("audio", "music_volume", -1.0)
	var ok: bool = (err == OK) and (abs(saved - 0.3) < 0.01)
	var msg: String = ""
	if ok:
		msg = "music_volume=%.2f" % saved
	else:
		msg = "err=%d saved=%.2f" % [err, saved]
	menu.queue_free()
	await get_tree().process_frame
	_tf.run_test("Settings 保存到 user://settings.cfg", func(): return {"pass": ok, "message": msg})

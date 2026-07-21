extends Node
## 7 章通关路径测试 — Driver 模式 (GDScript 自建, 借鉴 godot-test-driver)
## - 调 Stats.take_damage 触发战斗结局
## - 监听 game_state.boss_defeated + DialogueHelper.dialogue_started
## - watchdog 防卡死 (90s 总)

const TestFramework = preload("res://tests/test_framework.gd")

const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]

const TOTAL_TIMEOUT_SEC := 90.0

var _tf: TestFramework
var _current_scene: Node = null
var _started_at: float = 0.0

# 跨测试累积的信号计数
var _boss_defeated_count: int = 0
var _defeat_dialog_starts: int = 0
var _game_complete_triggered: bool = false


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_started_at = Time.get_ticks_msec()

	# 总 watchdog: 90s 整
	var watchdog = get_tree().create_timer(TOTAL_TIMEOUT_SEC)
	watchdog.timeout.connect(_on_watchdog)

	# 全局信号钩子 (autoload 信号源, 只需连一次)
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("boss_defeated"):
		gs.boss_defeated.connect(_on_boss_defeated_signal)

	var dh = get_node_or_null("/root/DialogueHelper")
	if dh and dh.has_signal("dialogue_started"):
		dh.dialogue_started.connect(_on_dialogue_started_signal)

	_tf.start_suite("playthrough")
	await _tf.run_test("main_menu loads with key buttons", _test_main_menu)
	if _timed_out(): return
	await _tf.run_test("7 chapter intro scenes load", _test_all_intros_load)
	if _timed_out(): return
	await _tf.run_test("7 chapter boss death triggers signals", _test_all_boss_signals)
	if _timed_out(): return
	await _tf.run_test("Ch7 boss death triggers game_complete", _test_game_complete)
	if _timed_out(): return

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- global hooks

var _timed_out_flag: bool = false
func _on_watchdog() -> void:
	_timed_out_flag = true
	print("\n⏰ WATCHDOG: %ds 总超时, 强制退出" % int(TOTAL_TIMEOUT_SEC))
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _timed_out() -> bool:
	return _timed_out_flag


func _on_boss_defeated_signal(_boss_name: String) -> void:
	_boss_defeated_count += 1


func _on_dialogue_started_signal(timeline: String) -> void:
	if timeline.ends_with("_boss_defeat.json"):
		_defeat_dialog_starts += 1
	elif timeline == "res://dialogs/game_complete.json":
		_game_complete_triggered = true


# ---------------------------------------------------------------- tests

func _test_main_menu() -> Dictionary:
	var scene = load("res://ui/main_menu.tscn")
	if scene == null:
		return {"pass": false, "message": "main_menu.tscn 加载失败"}
	var inst = scene.instantiate()
	add_child(inst)
	await get_tree().process_frame
	var new_btn = inst.has_node("CenterContainer/VBox/NewGameButton")
	var quit_btn = inst.has_node("CenterContainer/VBox/QuitButton")
	inst.queue_free()
	await get_tree().process_frame
	if not (new_btn and quit_btn):
		return {"pass": false, "message": "缺关键按钮"}
	return {"pass": true, "message": "New Game + Quit 按钮齐全"}


func _test_all_intros_load() -> Dictionary:
	var failed: Array = []
	for ch in range(1, 8):
		if _timed_out(): break
		var path = "res://scenes/levels/chapter_%d/chapter_%d_intro.tscn" % [ch, ch]
		var scene = load(path)
		if scene == null:
			failed.append("Ch%d 加载失败" % ch)
			continue
		var inst = scene.instantiate()
		add_child(inst)
		await get_tree().process_frame
		var has_player = inst.find_child("Player", true, false) != null
		inst.queue_free()
		await get_tree().process_frame
		if not has_player:
			failed.append("Ch%d 缺 Player" % ch)
		print("    Ch%d intro ok" % ch)
	if not failed.is_empty():
		return {"pass": false, "message": "; ".join(failed)}
	return {"pass": true, "message": "7/7 章 intro 加载并有 Player"}


func _test_all_boss_signals() -> Dictionary:
	if _timed_out():
		return {"pass": false, "message": "watchdog 已触发"}

	var failed: Array = []
	var initial_count := _boss_defeated_count
	var initial_defeat_dialog := _defeat_dialog_starts

	for ch in range(1, 8):
		if _timed_out(): break
		print("    [Ch%d] 进度: boss 已击败 %d 次" % [ch, _boss_defeated_count - initial_count])
		var result: Dictionary = await _test_chapter_boss_signal(ch)
		if not result.get("pass", false):
			failed.append("Ch%d: %s" % [ch, result.get("message", "")])

	var after_boss := _boss_defeated_count - initial_count
	var after_dialog := _defeat_dialog_starts - initial_defeat_dialog
	print("    [汇总] boss_defeated signal %d/7, defeat dialog %d/7" % [after_boss, after_dialog])

	if after_boss < 7:
		failed.append("boss_defeated 信号 %d 次 (< 7)" % after_boss)
	if after_dialog < 7:
		failed.append("defeat dialog %d 次 (< 7)" % after_dialog)
	if not failed.is_empty():
		return {"pass": false, "message": "; ".join(failed)}
	return {"pass": true, "message": "7/7 章 boss_defeated + defeat dialog 全部触发"}


func _test_chapter_boss_signal(ch: int) -> Dictionary:
	if _timed_out():
		return {"pass": false, "message": "watchdog"}

	var boss_name = BOSS_NAMES[ch - 1]
	var boss_path = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]

	await _cleanup_scene()

	var scene = load(boss_path)
	if scene == null:
		return {"pass": false, "message": "%s 加载失败" % boss_path}

	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout

	var boss = _find_boss(_current_scene, boss_name)
	if boss == null:
		await _cleanup_scene()
		return {"pass": false, "message": "没找到 Boss '%s'" % boss_name}

	var stats = boss.get_node_or_null("Stats")
	if stats == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss '%s' 缺 Stats" % boss_name}

	# 触发 boss death (直接 take_damage, 不 await 信号以免错过 emit)
	stats.take_damage(stats.max_health + 100)
	# 轮询 boss_killed 标志 (chapter_X._on_boss_defeated 设的)
	var waited := 0.0
	while waited < 3.0:
		await get_tree().process_frame
		waited += 1.0 / 60.0
		if _current_scene and "boss_killed" in _current_scene and _current_scene.boss_killed:
			break

	var boss_killed_flag := false
	if _current_scene and "boss_killed" in _current_scene:
		boss_killed_flag = _current_scene.boss_killed

	await _cleanup_scene()

	if not boss_killed_flag:
		return {"pass": false, "message": "_on_boss_defeated 未执行 (boss_killed=false after %.1fs)" % waited}
	return {"pass": true, "message": "Ch%d boss '%s' death → 链触发 ok (%.1fs)" % [ch, boss_name, waited]}


func _test_game_complete() -> Dictionary:
	if _timed_out():
		return {"pass": false, "message": "watchdog"}

	await _cleanup_scene()

	# Ch7 boss 关卡需要 Boss. 走 Onyx.boss_stats.health_depleted 链
	var path = "res://scenes/levels/chapter_7/chapter_7_boss.tscn"
	var scene = load(path)
	if scene == null:
		return {"pass": false, "message": "Ch7 boss scene 加载失败"}

	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout

	var boss = _find_boss(_current_scene, "Onyx")
	if boss == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Ch7 'Onyx' 没找到"}

	var stats = boss.get_node_or_null("Stats")
	if stats == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Onyx 缺 Stats"}

	# 重置 flag
	_game_complete_triggered = false
	# 预填 6 个碎片 (模拟前 6 关已通关), 第 7 个会在 Onyx._trigger_post_battle_dialogue 中加
	var gs = get_node_or_null("/root/GameState")
	if gs:
		for s in range(1, 7):
			gs.collect_shard(s)

	stats.take_damage(stats.max_health + 100)
	var waited := 0.0
	while waited < 4.0:
		await get_tree().process_frame
		waited += 1.0 / 60.0
		if _game_complete_triggered:
			break

	var ok := _game_complete_triggered
	await _cleanup_scene()

	if not ok:
		return {"pass": false, "message": "game_complete dialog 未触发 (%.1fs)" % waited}
	return {"pass": true, "message": "Onyx death → complete_game 链 → game_complete dialog (%.1fs)" % waited}


# ---------------------------------------------------------------- helpers

func _find_boss(scene: Node, name: String) -> Node:
	if scene == null:
		return null
	return scene.find_child(name, true, false)


func _cleanup_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
	await get_tree().process_frame

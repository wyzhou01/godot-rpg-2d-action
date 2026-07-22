extends Node
## V2.5 — 性能预算修真测试
##
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
## 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]

# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
const MAX_PHYSICS_FRAME_MS := 33.0  # 修真修真修真修真修真修真修真修真
const MAX_LOAD_TIME_MS := 3000.0  # 修真修真修真修真修真修真修真修真
const MAX_CHAPTER_CLEANUP_MS := 500.0  # 修真修真修真修真修真修真修真修真

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
	_tf.start_suite("perf_budget")

	await _test_chapter_load_time()
	await _test_chapter_cleanup_time()
	await _test_physics_frame_time_under_combat()
	await _test_memory_usage_stable()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- 修真修真修真修真

func _test_chapter_load_time() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var load_times: Array = []
	for ch in range(1, 8):
		var boss_name: String = BOSS_NAMES[ch - 1]
		var path: String = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]
		var t_start: int = Time.get_ticks_msec()
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		get_tree().root.add_child.call_deferred(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		var elapsed: int = Time.get_ticks_msec() - t_start
		load_times.append(elapsed)
		instance.queue_free()
		await get_tree().process_frame

	var max_load: float = 0.0
	var avg_load: float = 0.0
	if not load_times.is_empty():
		for t in load_times:
			max_load = max(max_load, float(t))
		avg_load = float(load_times.reduce(func(a, b): return a + b, 0)) / float(load_times.size())

	var passed: bool = max_load < MAX_LOAD_TIME_MS
	_tf.run_test("7 章加载时间 < %dms" % int(MAX_LOAD_TIME_MS), func() -> Dictionary:
		return {"pass": passed, "message": "max=%.0fms avg=%.0fms (7 章)" % [max_load, avg_load]})


func _test_chapter_cleanup_time() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var cleanup_times: Array = []
	for ch in range(1, 8):
		var path: String = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		get_tree().root.add_child.call_deferred(instance)
		await get_tree().process_frame
		await get_tree().process_frame

		var t_start: int = Time.get_ticks_msec()
		instance.queue_free()
		await get_tree().process_frame
		var elapsed: int = Time.get_ticks_msec() - t_start
		cleanup_times.append(elapsed)

	var max_cleanup: float = 0.0
	for t in cleanup_times:
		max_cleanup = max(max_cleanup, float(t))
	var passed: bool = max_cleanup < MAX_CHAPTER_CLEANUP_MS
	_tf.run_test("7 章 cleanup < %dms" % int(MAX_CHAPTER_CLEANUP_MS), func() -> Dictionary:
		return {"pass": passed, "message": "max=%.0fms (7 章)" % max_cleanup})


func _test_physics_frame_time_under_combat() -> void:
	var path: String = "res://scenes/levels/chapter_1/chapter_1_boss.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_tf.run_test("单帧 physics_frame < %dms" % int(MAX_PHYSICS_FRAME_MS), func() -> Dictionary:
			return {"pass": false, "message": "无法加载 chapter 1"})
		return
	var scene: Node = packed.instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = scene.find_child("Player", true, false)
	var boss: Node2D = scene.find_child(BOSS_NAMES[0], true, false)
	if player == null or boss == null:
		scene.queue_free()
		await get_tree().process_frame
		_tf.run_test("单帧 physics_frame < %dms" % int(MAX_PHYSICS_FRAME_MS), func() -> Dictionary:
			return {"pass": false, "message": "Player 或 Boss 缺失"})
		return

	_robot.set_player(player)
	player.global_position = boss.global_position + Vector2(-25, 0)
	player.facing = 1
	player.sprite.scale.x = 1
	player.hitbox_pivot.scale.x = 1
	await get_tree().physics_frame

	# 修真: 单帧修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var max_frame_ms: float = 0.0
	for i in range(30):
		var t_start: int = Time.get_ticks_msec()
		await get_tree().physics_frame
		var elapsed: float = float(Time.get_ticks_msec() - t_start)
		max_frame_ms = max(max_frame_ms, elapsed)

	_robot.release_all()
	scene.queue_free()
	await get_tree().process_frame

	var passed: bool = max_frame_ms < MAX_PHYSICS_FRAME_MS
	_tf.run_test("单帧 physics_frame < %dms" % int(MAX_PHYSICS_FRAME_MS), func() -> Dictionary:
		return {"pass": passed, "message": "max=%.2fms (30 个 frame)" % max_frame_ms})


func _test_memory_usage_stable() -> void:
	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var path: String = "res://scenes/levels/chapter_1/chapter_1_boss.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_tf.run_test("内存稳定 (7 次切换)", func() -> Dictionary:
			return {"pass": false, "message": "无法加载 chapter 1"})
		return

	var initial_objects: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var max_growth: int = 0
	for i in range(7):
		var instance: Node = packed.instantiate()
		get_tree().root.add_child.call_deferred(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		instance.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		var current_objects: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		max_growth = max(max_growth, current_objects - initial_objects)

	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var passed: bool = max_growth < 200
	_tf.run_test("内存稳定 (7 次切换)", func() -> Dictionary:
		return {"pass": passed, "message": "最大增长=%d 节点 (初始 %d)" % [max_growth, initial_objects]})

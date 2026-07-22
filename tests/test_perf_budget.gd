extends Node
## Test: perf_budget — physics frame timing under chapter 1 boss scene
## Replaces earlier single-max check (which always flagged startup spike
## at frame 0). Now samples N=30 frames after a small warmup so the test
## reflects steady-state, not first-instantiate collision registration.

const TestFramework = preload("res://tests/test_framework.gd")

# Budgets (tunable)
const MAX_LOAD_TIME_MS := 3000.0          # 7 chapters, sync load
const MAX_CHAPTER_CLEANUP_MS := 500.0    # 7 chapters, queue_free
const MAX_PHYSICS_FRAME_P95_MS := 33.0   # 30 FPS at p95
const MAX_PHYSICS_FRAME_ABS_MS := 100.0  # tolerated single-frame spike
const WARMUP_FRAMES := 2                 # discard deferred-queue frames
const SAMPLE_FRAMES := 30                # main sample window

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("perf_budget")

	await _test_chapter_load_time()
	await _test_chapter_cleanup_time()
	await _test_physics_frame_p95_under_combat()
	await _test_memory_usage_stable()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# --------------------------------------------------------------- chapter load

func _test_chapter_load_time() -> void:
	var load_times: Array = []
	for ch in range(1, 8):
		var path: String = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]
		var t_start: int = Time.get_ticks_msec()
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		load_times.append(Time.get_ticks_msec() - t_start)

	var max_load: float = 0.0
	var avg_load: float = 0.0
	if not load_times.is_empty():
		for t in load_times:
			max_load = max(max_load, float(t))
		avg_load = float(load_times.reduce(func(a, b): return a + b, 0)) / float(load_times.size())

	var passed: bool = max_load < MAX_LOAD_TIME_MS
	_tf.run_test("7 chapters load < %dms" % int(MAX_LOAD_TIME_MS), func() -> Dictionary:
		return {"pass": passed, "message": "max=%.0fms avg=%.0fms (7 chapters)" % [max_load, avg_load]})


# ------------------------------------------------------------- chapter cleanup

func _test_chapter_cleanup_time() -> void:
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
		cleanup_times.append(Time.get_ticks_msec() - t_start)

	var max_cleanup: float = 0.0
	for t in cleanup_times:
		max_cleanup = max(max_cleanup, float(t))
	var passed: bool = max_cleanup < MAX_CHAPTER_CLEANUP_MS
	_tf.run_test("7 chapters cleanup < %dms" % int(MAX_CHAPTER_CLEANUP_MS), func() -> Dictionary:
		return {"pass": passed, "message": "max=%.0fms (7 chapters)" % max_cleanup})


# ---------------------------------------------------------- physics frame p95

func _test_physics_frame_p95_under_combat() -> void:
	var path: String = "res://scenes/levels/chapter_1/chapter_1_boss.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_tf.run_test("p95 physics_frame < %dms (n=%d, warmup=%d)" % [int(MAX_PHYSICS_FRAME_P95_MS), SAMPLE_FRAMES, WARMUP_FRAMES], func() -> Dictionary:
			return {"pass": false, "message": "chapter 1 scene missing"})
		return

	var scene: Node = packed.instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = scene.find_child("Player", true, false)
	if player == null:
		scene.queue_free()
		await get_tree().process_frame
		_tf.run_test("p95 physics_frame < %dms (n=%d, warmup=%d)" % [int(MAX_PHYSICS_FRAME_P95_MS), SAMPLE_FRAMES, WARMUP_FRAMES], func() -> Dictionary:
			return {"pass": false, "message": "Player missing"})
		return

	# Warmup: discard first frames where deferred queues (collision
	# registration, AI state push) collapse into a single spike.
	for i in range(WARMUP_FRAMES):
		await get_tree().physics_frame

	# Sample: per-frame wall time
	var frame_times: Array = []
	for i in range(SAMPLE_FRAMES):
		var t_start: int = Time.get_ticks_msec()
		await get_tree().physics_frame
		frame_times.append(Time.get_ticks_msec() - t_start)

	scene.queue_free()
	await get_tree().process_frame

	if frame_times.is_empty():
		_tf.run_test("p95 physics_frame < %dms (n=%d, warmup=%d)" % [int(MAX_PHYSICS_FRAME_P95_MS), SAMPLE_FRAMES, WARMUP_FRAMES], func() -> Dictionary:
			return {"pass": false, "message": "no frames sampled"})
		return

	# Stats: min/max/mean/p95
	var min_f: float = 1e9
	var max_f: float = 0.0
	var sum_f: float = 0.0
	for t in frame_times:
		var f: float = float(t)
		min_f = min(min_f, f)
		max_f = max(max_f, f)
		sum_f += f
	var mean: float = sum_f / float(frame_times.size())

	var sorted_times: Array = frame_times.duplicate()
	sorted_times.sort()
	var p95_idx: int = int(ceil(0.95 * float(sorted_times.size()))) - 1
	p95_idx = clamp(p95_idx, 0, sorted_times.size() - 1)
	var p95: float = float(sorted_times[p95_idx])

	var p95_passed: bool = p95 < MAX_PHYSICS_FRAME_P95_MS
	var max_passed: bool = max_f < MAX_PHYSICS_FRAME_ABS_MS
	var passed: bool = p95_passed and max_passed

	_tf.run_test("p95 physics_frame < %dms (n=%d, warmup=%d)" % [int(MAX_PHYSICS_FRAME_P95_MS), SAMPLE_FRAMES, WARMUP_FRAMES], func() -> Dictionary:
		return {
			"pass": passed,
			"message": "min=%.2fms mean=%.2fms p95=%.2fms max=%.2fms (n=%d warmup=%d)" % [min_f, mean, p95, max_f, frame_times.size(), WARMUP_FRAMES],
		})


# ----------------------------------------------------------- memory stability

func _test_memory_usage_stable() -> void:
	var path: String = "res://scenes/levels/chapter_1/chapter_1_boss.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_tf.run_test("memory stable (7 toggles)", func() -> Dictionary:
			return {"pass": false, "message": "chapter 1 scene missing"})
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

	var passed: bool = max_growth < 200
	_tf.run_test("memory stable (7 toggles)", func() -> Dictionary:
		return {"pass": passed, "message": "max growth=%d nodes (initial=%d)" % [max_growth, initial_objects]})

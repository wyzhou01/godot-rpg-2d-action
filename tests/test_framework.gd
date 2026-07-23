extends Node
## 测试框架基类（Node 派生，支持 await 协程）

class_name TestFramework

var _test_results: Array = []
var _current_suite: String = ""
var _suite_start_time: int = 0
var _test_start_time: int = 0
var _total_assertions: int = 0
var _passed_assertions: int = 0
var _failed_assertions: int = 0
var _has_failures: bool = false


func _ready() -> void:
	pass


func start_suite(name: String) -> void:
	_current_suite = name
	print("\n" + "=".repeat(60))
	print("[SUITE] %s" % name)
	print("=".repeat(60))
	_suite_start_time = Time.get_ticks_msec()


func end_suite() -> void:
	var elapsed = Time.get_ticks_msec() - _suite_start_time
	print("[SUITE END] %s (%.2fs)" % [_current_suite, elapsed / 1000.0])


## 跑一个测试
## callable 必须返回 Dictionary（含 "pass" 字段）或 {"pass": false, "message": "..."}
func run_test(name: String, callable: Callable) -> void:
	print("\n[TEST] %s" % name)
	_test_start_time = Time.get_ticks_msec()
	var status: String = "PASS"
	var message: String = ""
	
	# 调用测试函数 — await 让 coroutine 跑完
	var result: Variant = await callable.call()
	
	# 如果结果是 Dictionary，提取结果
	if result is Dictionary:
		if result.get("pass", true) == false:
			status = "FAIL"
			message = result.get("message", "")
			_has_failures = true
		elif result.get("skip", false):
			status = "SKIP"
			message = result.get("message", "")
	
	var elapsed = Time.get_ticks_msec() - _test_start_time
	_test_results.append({
		"suite": _current_suite,
		"name": name,
		"status": status,
		"message": message,
		"duration_ms": elapsed,
	})
	
	if status == "FAIL":
		print("  [FAIL] %s" % message)
	elif status == "SKIP":
		print("  [SKIP] %s" % message)
	else:
		print("  [PASS] (%dms)" % elapsed)


func assert_true(condition: bool, msg: String = "Expected true") -> void:
	_total_assertions += 1
	if not condition:
		_failed_assertions += 1
		_has_failures = true
		printerr("    ✗ ASSERTION FAILED: " + msg)
		assert(false, msg)
	else:
		_passed_assertions += 1


func assert_eq(actual, expected, msg: String = "") -> void:
	_total_assertions += 1
	if actual != expected:
		_failed_assertions += 1
		_has_failures = true
		var prefix = "    ✗ ASSERTION FAILED" if msg.is_empty() else ("    ✗ " + msg)
		printerr("%s\n      Expected: %s\n      Got:      %s" % [prefix, str(expected), str(actual)])
	else:
		_passed_assertions += 1


func assert_ne(actual, not_expected, msg: String = "") -> void:
	_total_assertions += 1
	if actual == not_expected:
		_failed_assertions += 1
		_has_failures = true
		var prefix = "    ✗ ASSERTION FAILED" if msg.is_empty() else ("    ✗ " + msg)
		printerr("%s\n      Should NOT be: %s\n      Got:           %s" % [prefix, str(not_expected), str(actual)])
	else:
		_passed_assertions += 1


func assert_not_null(obj, msg: String = "Should not be null") -> void:
	assert_true(obj != null, msg + " (was null)")


func assert_null(obj, msg: String = "Should be null") -> void:
	assert_true(obj == null, msg + " (was " + str(obj) + ")")


func assert_has_method(obj, method_name: String) -> void:
	assert_true(obj != null and obj.has_method(method_name), "Object should have method: " + method_name)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func load_scene(path: String) -> Node:
	if not ResourceLoader.exists(path):
		printerr("Scene not found: " + path)
		return null
	return load(path).instantiate()


func add_scene_to_root(scene: Node) -> void:
	get_tree().root.add_child(scene)


func cleanup_scene(scene: Node) -> void:
	if scene and is_instance_valid(scene):
		scene.queue_free()


func print_summary() -> void:
	print("\n" + "=".repeat(60))
	print("TEST SUMMARY")
	print("=".repeat(60))
	var passed = 0
	var failed = 0
	var skipped = 0
	for r in _test_results:
		match r.status:
			"PASS": passed += 1
			"FAIL":
				failed += 1
				print("  ❌ [FAIL] %s > %s: %s" % [r.suite, r.name, r.message])
			"SKIP":
				skipped += 1
				print("  ⏭ [SKIP] %s > %s: %s" % [r.suite, r.name, r.message])
	print("\nResults: %d PASS / %d FAIL / %d SKIP" % [passed, failed, skipped])
	print("Assertions: %d / %d passed" % [_passed_assertions, _total_assertions])
	print("Total tests: %d" % _test_results.size())


func has_failures() -> bool:
	return _has_failures


func exit_with_result() -> void:
	if _has_failures:
		print("\n❌ TEST SUITE FAILED")
		get_tree().quit(1)
	else:
		print("\n✅ ALL TESTS PASSED")
		get_tree().quit(0)

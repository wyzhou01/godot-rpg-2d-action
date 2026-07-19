extends Node
## 存档系统测试

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework
var _save_system: Node = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_run_all()


func _run_all() -> void:
	_tf.start_suite("save_system")
	
	_save_system = get_node_or_null("/root/SaveSystem")
	if _save_system == null:
		print("❌ SaveSystem autoload not found")
		get_tree().quit(1)
		return
	
	_cleanup_saves()
	
	_tf.run_test("save_game writes file", _test_save_writes_file)
	_tf.run_test("has_save returns true after save", _test_has_save)
	_tf.run_test("load_save returns data", _test_load_save)
	_tf.run_test("4 slots independent", _test_four_slots)
	_tf.run_test("invalid slot rejected", _test_invalid_slot)
	_tf.run_test("overwrite existing save", _test_overwrite)
	
	_cleanup_saves()
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _cleanup_saves() -> void:
	for i in 4:
		var path = "user://saves/save_%d.json" % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_save_writes_file() -> Dictionary:
	var result = _save_system.save_game(0, {"current_chapter": 1, "test": true})
	if not result:
		return {"pass": false, "message": "save_game returned false"}
	if not FileAccess.file_exists("user://saves/save_0.json"):
		return {"pass": false, "message": "save_0.json not created"}
	return {"pass": true}


func _test_has_save() -> Dictionary:
	if not _save_system.has_save(0):
		return {"pass": false, "message": "has_save(0) returned false"}
	return {"pass": true}


func _test_load_save() -> Dictionary:
	var data = _save_system.load_save(0)
	if data == null or data.is_empty():
		return {"pass": false, "message": "load_save returned null/empty"}
	if data.get("current_chapter") != 1:
		return {"pass": false, "message": "current_chapter not 1"}
	return {"pass": true}


func _test_four_slots() -> Dictionary:
	_save_system.save_game(0, {"slot": 0})
	_save_system.save_game(1, {"slot": 1})
	_save_system.save_game(2, {"slot": 2})
	_save_system.save_game(3, {"slot": 3})
	for i in 4:
		if not _save_system.has_save(i):
			return {"pass": false, "message": "Slot %d missing" % i}
		var d = _save_system.load_save(i)
		if d.get("slot") != i:
			return {"pass": false, "message": "Slot %d wrong data" % i}
	return {"pass": true}


func _test_invalid_slot() -> Dictionary:
	if _save_system.save_game(-1, {}):
		return {"pass": false, "message": "save_game(-1) should fail"}
	if _save_system.save_game(99, {}):
		return {"pass": false, "message": "save_game(99) should fail"}
	return {"pass": true}


func _test_overwrite() -> Dictionary:
	_save_system.save_game(0, {"version": 1})
	_save_system.save_game(0, {"version": 2})
	var d = _save_system.load_save(0)
	if d.get("version") != 2:
		return {"pass": false, "message": "Overwrite failed: version is %s" % d.get("version")}
	return {"pass": true}

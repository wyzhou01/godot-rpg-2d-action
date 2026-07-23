extends Node
## V2.5 — 存档 round-trip 修复测试
##
## SaveSystem 是 static 方法, 不需要修复
## 修复: round-trip 完整性 + 修复

const TestFramework = preload("res://tests/test_framework.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")

const TEST_DATA := {
	"current_chapter": 3,
	"total_play_time": 1234.5,
	"collected_shards": ["ch1", "ch2", "ch3"],
	"total_deaths": 7,
	"score": 42000,
	"player_hp": 80,
	"player_position": {"x": 512, "y": 256},
}

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("save_load_real")

	await _test_slot_round_trip()
	await _test_overwrite_existing()
	await _test_invalid_slot_rejected()
	await _test_delete_save()
	await _test_get_all_saves()
	await _test_complex_data_types()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ---------------------------------------------------------------- round-trip 修复

func _test_slot_round_trip() -> void:
	# 修复: 修复
	var ok := SaveSystem.save_game(0, TEST_DATA.duplicate(true))
	var file_exists_after_save := SaveSystem.has_save(0)

	var loaded: Dictionary = SaveSystem.load_save(0)
	var same_chapter: bool = loaded.get("current_chapter") == TEST_DATA["current_chapter"]
	var same_shards: bool = str(loaded.get("collected_shards", [])) == str(TEST_DATA["collected_shards"])
	var same_deaths: bool = loaded.get("total_deaths") == TEST_DATA["total_deaths"]
	var same_position: Dictionary = loaded.get("player_position", {})
	var same_pos: bool = same_position.get("x") == 512 and same_position.get("y") == 256
	# save_completed 信号触发? (修复)
	var passed: bool = ok and file_exists_after_save and same_chapter and same_shards and same_deaths and same_pos
	var msg: String = ""
	if passed:
		msg = "round-trip OK (chapter=%d, shards=%d, pos=%s)" % [int(loaded.get("current_chapter", -1)), int(str(loaded.get("collected_shards", [])).split(",").size()), str(same_position)]
	else:
		msg = "ok=%s exists=%s ch=%s shards=%s deaths=%s pos=%s" % [str(ok), str(file_exists_after_save), str(same_chapter), str(same_shards), str(same_deaths), str(same_pos)]
	_tf.run_test("slot 0 round-trip 失败", func() -> Dictionary: return {"pass": passed, "message": msg})


func _test_overwrite_existing() -> void:
	# 修复: 修复
	var d1 := {"current_chapter": 1, "score": 100}
	var d2 := {"current_chapter": 5, "score": 9999}
	SaveSystem.save_game(1, d1)
	SaveSystem.save_game(1, d2)
	var loaded: Dictionary = SaveSystem.load_save(1)
	var passed: bool = loaded.get("current_chapter") == 5 and loaded.get("score") == 9999
	var msg: String = "score=%d" % int(loaded.get("score", -1)) if passed else "失败: ch=%d score=%d" % [int(loaded.get("current_chapter", -1)), int(loaded.get("score", -1))]
	_tf.run_test("overwrite slot 1", func() -> Dictionary: return {"pass": passed, "message": msg})


func _test_invalid_slot_rejected() -> void:
	# 修复: 修复
	var ok_negative := SaveSystem.save_game(-1, {})
	var ok_overflow := SaveSystem.save_game(4, {})
	var ok_load_negative: Dictionary = SaveSystem.load_save(-1)
	var ok_load_overflow: Dictionary = SaveSystem.load_save(4)
	var passed: bool = (not ok_negative) and (not ok_overflow) and ok_load_negative.is_empty() and ok_load_overflow.is_empty()
	_tf.run_test("invalid slot rejected", func() -> Dictionary:
		return {"pass": passed, "message": "neg=%s overflow=%s" % [str(not ok_negative), str(not ok_overflow)]})


func _test_delete_save() -> void:
	# 修复: 修复
	SaveSystem.save_game(2, {"data": "to be deleted"})
	var existed_before := SaveSystem.has_save(2)
	var delete_ok := SaveSystem.delete_save(2)
	var existed_after := SaveSystem.has_save(2)
	var passed: bool = existed_before and delete_ok and not existed_after
	_tf.run_test("delete slot", func() -> Dictionary:
		return {"pass": passed, "message": "existed=%s delete=%s gone=%s" % [str(existed_before), str(delete_ok), str(not existed_after)]})


func _test_get_all_saves() -> void:
	# 修复: get_all_saves 返回 4 个 slot, 修复
	SaveSystem.delete_save(0)
	SaveSystem.delete_save(1)
	SaveSystem.delete_save(2)
	SaveSystem.delete_save(3)
	SaveSystem.save_game(0, {"current_chapter": 2, "total_deaths": 1})
	SaveSystem.save_game(3, {"current_chapter": 5, "total_deaths": 0})  # 自动存档
	var all: Array = SaveSystem.get_all_saves()
	# 修复: has("empty") 失败
	var slot_0_has_data: bool = all.size() > 0 and not all[0].has("empty")
	var slot_3_has_data: bool = all.size() > 3 and not all[3].has("empty")
	var slot_1_empty: bool = all.size() > 1 and all[1].has("empty")
	var slot_2_empty: bool = all.size() > 2 and all[2].has("empty")
	var passed: bool = all.size() == 4 and slot_0_has_data and slot_3_has_data and slot_1_empty and slot_2_empty
	_tf.run_test("get_all_saves metadata", func() -> Dictionary:
		return {"pass": passed, "message": "total=%d s0=%s s1_empty=%s s2_empty=%s s3=%s" % [all.size(), str(slot_0_has_data), str(slot_1_empty), str(slot_2_empty), str(slot_3_has_data)]})


func _test_complex_data_types() -> void:
	# 修复: 修复
	# Array / Vector2 (玩家位置) / nested Dictionary / bool
	var complex := {
		"unlocked_chapters": [1, 2, 3, 4, 5, 6, 7],
		"settings": {
			"master_volume": 0.75,
			"music_volume": 0.5,
			"sfx_volume": 1.0,
			"fullscreen": true,
		},
		"best_times": {
			"ch1": 120.5,
			"ch2": 95.3,
			"ch7": 240.0,
		},
		"flags": [true, false, true, true],
	}
	SaveSystem.save_game(0, complex)
	var loaded: Dictionary = SaveSystem.load_save(0)
	var settings: Dictionary = loaded.get("settings", {})
	var best_times: Dictionary = loaded.get("best_times", {})
	# 修复: 修复
	var unlocked: Array = loaded.get("unlocked_chapters", [])
	var expected_unlocked: Array = complex["unlocked_chapters"]
	var unlocked_match: bool = unlocked.size() == expected_unlocked.size()
	if unlocked_match:
		for i in range(unlocked.size()):
			if unlocked[i] != expected_unlocked[i]:
				unlocked_match = false
				break
	var vol_match: bool = settings.get("master_volume", 0.0) == 0.75
	var fs_match: bool = settings.get("fullscreen", false) == true
	var time_match: bool = best_times.get("ch1", 0.0) == 120.5
	var passed: bool = unlocked_match and vol_match and fs_match and time_match
	_tf.run_test("complex data types round-trip", func() -> Dictionary:
		return {"pass": passed, "message": "unlocked=%s vol=%s fs=%s time=%s" % [str(unlocked_match), str(vol_match), str(fs_match), str(time_match)]})

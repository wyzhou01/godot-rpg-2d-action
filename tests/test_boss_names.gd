extends Node
## Boss 名字唯一性测试
## 防止 Ch2-7 重新出现"通用 Boss"节点名（7-19 已经踩过这个坑）

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework

# 7 个 Boss 各自的专属名字（不能有重叠或缺失）
const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("boss_names")
	await _tf.run_test("7 boss names unique", _test_unique_names)
	await _tf.run_test("all 7 boss scenes load", _test_all_scenes_load)
	await _tf.run_test("each boss scene has stats node", _test_stats_present)
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _test_unique_names() -> Dictionary:
	var seen := {}
	for n in BOSS_NAMES:
		if seen.has(n):
			return {"pass": false, "message": "Boss '%s' 出现重复" % n}
		seen[n] = true
	if BOSS_NAMES.size() != 7:
		return {"pass": false, "message": "只有 %d 个 Boss, 期望 7" % BOSS_NAMES.size()}
	return {"pass": true, "message": "7/7 名字唯一: " + ", ".join(BOSS_NAMES)}


func _test_all_scenes_load() -> Dictionary:
	var missing := []
	for ch in range(1, 8):
		var path = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]
		var scene = load(path)
		if scene == null:
			missing.append(path)
	if not missing.is_empty():
		return {"pass": false, "message": "缺失: " + ", ".join(missing)}
	return {"pass": true, "message": "7/7 boss 场景加载成功"}


func _test_stats_present() -> Dictionary:
	var ch_with_boss := []
	var ch_without_stats := []
	for ch in range(1, 8):
		var path = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]
		var scene = load(path)
		if scene == null:
			continue
		var inst = scene.instantiate()
		add_child(inst)
		await get_tree().process_frame
		var boss_name = BOSS_NAMES[ch - 1]
		var boss_node = inst.find_child(boss_name, true, false)
		if boss_node == null:
			inst.queue_free()
			ch_without_stats.append("Ch%d: 没找到节点 '%s'" % [ch, boss_name])
			continue
		var stats = boss_node.get_node_or_null("Stats")
		if stats == null:
			inst.queue_free()
			ch_without_stats.append("Ch%d: '%s' 缺 Stats 子节点" % [ch, boss_name])
			continue
		ch_with_boss.append("Ch%d:%s" % [ch, boss_name])
		inst.queue_free()
	if not ch_without_stats.is_empty():
		return {"pass": false, "message": "问题: " + "; ".join(ch_without_stats)}
	return {"pass": true, "message": "%d/7 boss 节点 + Stats 齐全: %s" % [ch_with_boss.size(), ", ".join(ch_with_boss)]}

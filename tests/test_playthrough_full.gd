extends Node
## V2.5.1 — 真玩家跨 7 章全程跑测试
##

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]

var _tf: TestFramework
var _robot: RobotPlayer = null
var _current_scene: Node = null
var _gs: Node = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_robot = RobotPlayer.new()
	add_child(_robot)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("playthrough_full")

	PlayerData.reset_for_new_game()
	_gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if _gs:
		_gs.collected_shards = []
		_gs.defeated_bosses = []

	for ch in range(1, 8):
		_robot.release_all()
		var boss_name: String = BOSS_NAMES[ch - 1]
		var result: Dictionary = await _run_chapter(ch, boss_name)
		_tf.run_test("Ch%d %s 失败" % [ch, boss_name], func() -> Dictionary: return result)
		await _cleanup_scene()

	await _test_game_complete_after_all_bosses()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _run_chapter(ch: int, boss_name: String) -> Dictionary:
	var intro_path: String = "res://scenes/levels/chapter_%d/chapter_%d_intro.tscn" % [ch, ch]
	var boss_path: String = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]

	var scene = load(intro_path)
	if scene == null:
		return {"pass": false, "message": "%s 失败" % intro_path}
	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	for i in range(20):
		await _robot.wait_physics_frames(1)
		await _press_ui_accept_safe()
		await get_tree().process_frame
		var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
		if dh and not dh.is_showing():
			break

	await _cleanup_scene()

	var boss_scene = load(boss_path)
	if boss_scene == null:
		return {"pass": false, "message": "%s 失败" % boss_path}
	_current_scene = boss_scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = _current_scene.find_child("Player", true, false)
	var boss: Node2D = _current_scene.find_child(boss_name, true, false)
	if player == null:
		return {"pass": false, "message": "Player 失败"}
	if boss == null:
		return {"pass": false, "message": "%s 失败" % boss_name}

	boss.set_physics_process(false)
	var detection = boss.get_node_or_null("PlayerDetectionZone")
	if detection:
		detection.set_physics_process(false)

	var hurt_box = player.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.invulnerable = true
		hurt_box.monitoring = false

	_robot.set_player(player)
	player.global_position = boss.global_position + Vector2(-25, 0)
	player.facing = 1
	player.sprite.scale.x = 1
	player.hitbox_pivot.scale.x = 1
	await get_tree().physics_frame

	var boss_stats = boss.get_node_or_null("Stats")
	if boss_stats == null:
		return {"pass": false, "message": "Boss 失败 Stats"}
	var max_iter := 25
	var iter := 0
	var last_hp: int = boss_stats.health
	var hits := 0
	while iter < max_iter and boss_stats.health > 0:
		player.global_position = boss.global_position + Vector2(-25, 0)
		player.facing = 1
		player.sprite.scale.x = 1
		player.hitbox_pivot.scale.x = 1
		await get_tree().physics_frame
		await _robot.attack(1)
		await get_tree().physics_frame
		await get_tree().physics_frame
		if boss_stats.health < last_hp:
			hits += 1
			last_hp = boss_stats.health
		player.global_position = boss.global_position + Vector2(-200, 0)
		await get_tree().physics_frame
		iter += 1

	if boss_stats.health > 0:
		return {"pass": false, "message": "Ch%d 失败: HP=%d hits=%d" % [ch, boss_stats.health, hits]}

	if _gs and not boss_name in _gs.defeated_bosses:
		return {"pass": false, "message": "GameState.defeated_bosses 失败 %s" % boss_name}

	if not _current_scene.boss_killed:
		return {"pass": false, "message": "boss_killed 失败 false"}

	return {
		"pass": true,
		"message": "Ch%d %s 失败 (hits=%d)" % [ch, boss_name, hits]
	}


func _press_ui_accept_safe() -> void:
	await get_tree().physics_frame
	Input.action_press("ui_accept", 1.0)
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().process_frame


func _test_game_complete_after_all_bosses() -> void:
	_gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if _gs == null:
		_tf.run_test("失败", func() -> Dictionary:
			return {"pass": false, "message": "GameState 失败"})
		return

	if _gs.defeated_bosses.size() < 7:
		_tf.run_test("失败", func() -> Dictionary:
			return {"pass": false, "message": "失败: defeated=%d/7" % _gs.defeated_bosses.size()})
		return

	for ch in range(1, 8):
		_gs.collect_shard(ch)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh == null:
		_tf.run_test("失败", func() -> Dictionary:
			return {"pass": false, "message": "DialogueHelper 失败"})
		return

	var state: Dictionary = {"complete_started": false}
	var on_started := func(_t: String) -> void:
		state["complete_started"] = true
	dh.dialogue_started.connect(on_started)

	_gs.complete_game()
	await get_tree().process_frame
	await get_tree().process_frame

	dh.dialogue_started.disconnect(on_started)

	var passed: bool = state["complete_started"] or dh.is_showing()
	_tf.run_test("失败", func() -> Dictionary:
		return {"pass": passed, "message": "失败: started=%s, showing=%s, shards=%d" % [
			str(state["complete_started"]), str(dh.is_showing()), _gs.collected_shards.size()
		]})


func _cleanup_scene() -> void:
	if _robot:
		_robot.release_all()
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
	await get_tree().process_frame

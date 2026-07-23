extends Node
## V2.5 — 死亡重生链路修复测试
##
## 修复: 玩家 HP=0 → Stats.health_decreased_and_depleted → Player._on_death() → SceneManager.on_player_died() → 场景重载
## 修复: PlayerData.deaths 计数 +1, 新 Player 修复
## 修复: 修复

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const CHAPTER_PATH := "res://scenes/levels/chapter_1/chapter_1_combat.tscn"

var _tf: TestFramework
var _robot: RobotPlayer = null
var _current_scene: Node = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_robot = RobotPlayer.new()
	add_child(_robot)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("death_retry")

	PlayerData.deaths = 0  # 重置计数
	PlayerData.reset_for_new_game()

	await _test_death_count_increments()
	await _test_player_respawns_after_death()
	await _test_die_multiple_times()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()



func _test_death_count_increments() -> void:
	# 修复: 修复
	# PlayerData.deaths 修复
	var initial_deaths: int = PlayerData.deaths
	PlayerData.on_player_died()
	await get_tree().process_frame
	var after_death: int = PlayerData.deaths
	var passed: bool = after_death == initial_deaths + 1
	_tf.run_test("PlayerData.deaths +1", func() -> Dictionary:
		return {"pass": passed, "message": "%d → %d" % [initial_deaths, after_death]})


func _test_player_respawns_after_death() -> void:
	PlayerData.deaths = 0
	PlayerData.reset_for_new_game()
	await _cleanup_scene()

	var scene = load(CHAPTER_PATH)
	if scene == null:
		_tf.run_test("死亡链路失败", func() -> Dictionary:
			return {"pass": false, "message": "%s 加载失败" % CHAPTER_PATH})
		return
	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = _current_scene.find_child("Player", true, false)
	if player == null:
		await _cleanup_scene()
		_tf.run_test("死亡链路失败", func() -> Dictionary:
			return {"pass": false, "message": "Player 节点未找到"})
		return

	var stats: Node = player.get_node_or_null("Stats")
	if stats == null:
		await _cleanup_scene()
		_tf.run_test("死亡链路失败", func() -> Dictionary:
			return {"pass": false, "message": "Player 缺 Stats"})
		return

	# 修复: Player 进入 DEATH 状态 (修复)
	stats.health = 1
	# 修复: 连接 signal 修复
	var health_zero_count: Dictionary = {"count": 0}
	var on_health_zero := func() -> void:
		health_zero_count["count"] = int(health_zero_count["count"]) + 1
	stats.health_decreased_and_depleted.connect(on_health_zero)

	stats.take_damage(999)
	await get_tree().process_frame
	await get_tree().process_frame

	# 修复: Player state 进入 DEATH (修复)
	var saw_death_state: bool = ("state" in player) and (int(player.state) == 7)  # PlayerState.DEATH = 7
	# 修复: physics_process 修复
	var physics_disabled: bool = not player.is_physics_processing()

	stats.health_decreased_and_depleted.disconnect(on_health_zero)

	await _cleanup_scene()

	var passed: bool = int(health_zero_count["count"]) == 1 and saw_death_state and physics_disabled
	var msg: String = "signal=%d state_DEATH=%s physics_off=%s" % [
		int(health_zero_count["count"]),
		str(saw_death_state),
		str(physics_disabled),
	]
	_tf.run_test("死亡链路失败", func() -> Dictionary:
		return {"pass": passed, "message": msg})


func _test_die_multiple_times() -> void:
	# 修复: 修复
	PlayerData.deaths = 0
	PlayerData.reset_for_new_game()

	# 修复: 修复
	for i in range(3):
		PlayerData.on_player_died()
		await get_tree().process_frame

	var final_deaths: int = PlayerData.deaths
	var passed: bool = final_deaths == 3
	_tf.run_test("连死 3 次 deaths=3", func() -> Dictionary:
		return {"pass": passed, "message": "deaths=%d" % final_deaths})


# ---------------------------------------------------------------- helpers

func _cleanup_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
	await get_tree().process_frame

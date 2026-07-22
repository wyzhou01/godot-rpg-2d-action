extends Node
## V2.5 — 真 input 战斗测试 (RobotPlayer 驱动)
##
## 修真 V2.3 combat_battle: 不再 teleport + Geometry2D overlap 模拟攻击
## 修真: 用 RobotPlayer 真按 attack, Player 真读 Input, 真放 HitBox
## 修真: Boss 真检测 Player 在 HurtBox 里 → take_damage
##
## 必须修真后 V2.3 测试也仍然通过 (向后兼容)

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]
const CHAPTER_TIMEOUT_SEC := 60.0
const TOTAL_TIMEOUT_SEC := 120.0

var _tf: TestFramework
var _current_scene: Node = null
var _timed_out_flag: bool = false
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
	var watchdog = get_tree().create_timer(TOTAL_TIMEOUT_SEC)
	watchdog.timeout.connect(_on_total_watchdog)

	_tf.start_suite("real_input_combat")
	for ch in range(1, 8):
		if _timed_out(): break
		var result: Dictionary = await _test_chapter_real_input(ch)
		_tf.run_test("Ch%d 真 input 通关" % ch, func() -> Dictionary: return result)
		# 测试间必须释放所有按键, 否则残留影响下一章
		_robot.release_all()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _on_total_watchdog() -> void:
	_timed_out_flag = true
	print("\n⏰ 总 watchdog 触发")
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _timed_out() -> bool:
	return _timed_out_flag


# ---------------------------------------------------------------- single chapter

func _test_chapter_real_input(ch: int) -> Dictionary:
	if _timed_out():
		return {"pass": false, "message": "watchdog"}

	var boss_name = BOSS_NAMES[ch - 1]
	var path = "res://scenes/levels/chapter_%d/chapter_%d_boss.tscn" % [ch, ch]

	await _cleanup_scene()

	var scene = load(path)
	if scene == null:
		return {"pass": false, "message": "%s 加载失败" % path}

	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = _find_node(_current_scene, "Player")
	var boss := _find_node(_current_scene, boss_name)
	if player == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Player 节点未找到"}
	if boss == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss '%s' 未找到" % boss_name}

	# 锁 Boss 不动 (修真真实测试时 Boss 会自己动, 这里只验证战斗链路)
	boss.set_physics_process(false)
	var detection = boss.get_node_or_null("PlayerDetectionZone")
	if detection:
		detection.set_physics_process(false)

	# 设置 Robot Player 追踪
	_robot.set_player(player)

	# 玩家无敌 (修真只验证攻击链路, 不修真 Boss 攻击模式)
	var hurt_box = player.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.invulnerable = true
		hurt_box.monitoring = false

	# 玩家初始位置: Boss 左侧 30px
	var boss_pos = boss.global_position
	player.global_position = boss_pos + Vector2(-30, 0)

	# 玩家面向 Boss
	player.facing = 1  # Boss 在右侧
	player.sprite.scale.x = 1
	player.hitbox_pivot.scale.x = 1

	await get_tree().create_timer(0.3).timeout

	var boss_stats = boss.get_node_or_null("Stats")
	if boss_stats == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss '%s' 缺 Stats" % boss_name}
	var initial_boss_hp = boss_stats.health
	if initial_boss_hp <= 0:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss.hp 已是 0"}

	# === 真 input 战斗 ===
	# 每轮:
	#   - 修真位置到 overlap 范围
	#   - 修真面向 Boss
	#   - RobotPlayer.attack() (修真真按 attack)
	#   - 等 Boss.hp 变化
	#   - 修真离开 overlap (后撤)
	var hits := 0
	var last_hp: int = boss_stats.health
	print("    [Ch%d] Boss 初始 HP: %d, RobotPlayer 开始真 input 攻击" % [ch, initial_boss_hp])

	var max_iterations := 30
	var watchdog_single = get_tree().create_timer(CHAPTER_TIMEOUT_SEC)
	var chapter_watchdog_hit := false
	watchdog_single.timeout.connect(func(): chapter_watchdog_hit = true)

	var iter := 0
	while iter < max_iterations and not _timed_out() and not chapter_watchdog_hit:
		iter += 1

		# 修真玩家位置到 overlap 范围
		player.global_position = boss_pos + Vector2(-25, 0)
		player.facing = 1
		player.sprite.scale.x = 1
		player.hitbox_pivot.scale.x = 1
		await get_tree().physics_frame

		# 真 input 攻击 (修真真按 attack, Player._read_input 读到, _change_state(ATTACK))
		await _robot.attack(1)

		# 等物理帧, 让 HitBox 真碰到 HurtBox, Boss take_damage
		await get_tree().physics_frame
		await get_tree().physics_frame

		# 检查 HP 变化
		if boss_stats.health < last_hp:
			hits += 1
			last_hp = boss_stats.health
			if iter % 5 == 0 or hits == 1:
				print("    [Ch%d] iter=%d HP=%d hits=%d" % [ch, iter, boss_stats.health, hits])

		if boss_stats.health <= 0:
			break

		# 后撤 (修真下次能正常攻击)
		player.global_position = boss_pos + Vector2(-200, 0)
		await get_tree().physics_frame

	# === 修真结果 ===
	var final_hp = boss_stats.health
	var boss_killed_flag := false
	if _current_scene and "boss_killed" in _current_scene:
		boss_killed_flag = _current_scene.boss_killed

	await _cleanup_scene()

	if chapter_watchdog_hit:
		return {"pass": false, "message": "Ch%d 单章超时 (60s, hits=%d)" % [ch, hits]}
	if final_hp > 0:
		return {"pass": false, "message": "Ch%d 没打死 Boss (HP=%d, hits=%d)" % [ch, final_hp, hits]}
	if not boss_killed_flag:
		return {"pass": false, "message": "Boss HP=0 但 chapter.boss_killed=false"}

	return {
		"pass": true,
		"message": "Ch%d 真 input 通关 (iters=%d hits=%d)" % [ch, iter, hits]
	}


# ---------------------------------------------------------------- helpers

func _find_node(scene: Node, name: String) -> Node:
	if scene == null:
		return null
	return scene.find_child(name, true, false)


func _cleanup_scene() -> void:
	if _robot:
		_robot.release_all()
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
	await get_tree().process_frame
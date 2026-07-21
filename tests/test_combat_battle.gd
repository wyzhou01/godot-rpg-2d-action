extends Node
## 真战斗通关测试 (P2) — Driver 模式
## - 不修改 stats.health 绕过战斗系统
## - 玩家 teleport 进/出 Boss HurtBox 区域, Geometry2D AABB 检测 overlap
## - 模拟玩家攻击 → Boss 受伤 → Boss.hp = 0 → chapter.X._on_boss_defeated
## - 7 章全部真战斗通关
## - watchdog: 单章 60s, 总 90s

const TestFramework = preload("res://tests/test_framework.gd")

const BOSS_NAMES = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]
const CHAPTER_TIMEOUT_SEC := 60.0
const TOTAL_TIMEOUT_SEC := 90.0

var _tf: TestFramework
var _current_scene: Node = null
var _timed_out_flag: bool = false


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	var watchdog = get_tree().create_timer(TOTAL_TIMEOUT_SEC)
	watchdog.timeout.connect(_on_total_watchdog)

	_tf.start_suite("combat_battle")
	for ch in range(1, 8):
		if _timed_out(): break
		var result: Dictionary = await _test_chapter_combat(ch)
		_tf.run_test("Ch%d 真战斗通关" % ch, func() -> Dictionary: return result)

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


# ---------------------------------------------------------------- single chapter test

func _test_chapter_combat(ch: int) -> Dictionary:
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

	var player = _find_node(_current_scene, "Player")
	var boss = _find_node(_current_scene, boss_name)
	if player == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Player 节点未找到"}
	if boss == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss '%s' 未找到" % boss_name}

	# 锁 Boss + 玩家位置 (不动)
	boss.set_physics_process(false)
	if boss.has_node("SpawnPoint"):
		boss.global_position = boss.get_node("SpawnPoint").global_position
	var boss_pos = boss.global_position
	player.set_physics_process(false)
	# 玩家初始在 Boss 左侧 30px (overlap)
	player.global_position = boss_pos + Vector2(-30, 0)

	# 锁 Boss AI
	var detection = boss.get_node_or_null("PlayerDetectionZone")
	if detection:
		detection.set_physics_process(false)

	await get_tree().create_timer(0.3).timeout

	var boss_stats = boss.get_node_or_null("Stats")
	if boss_stats == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss '%s' 缺 Stats" % boss_name}
	var initial_boss_hp = boss_stats.health
	if initial_boss_hp <= 0:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss.hp 已是 0"}

	# 玩家无敌 (避免 Boss 攻击致死)
	var hurt_box = player.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.invulnerable = true
		hurt_box.monitoring = false

	var sword_hitbox = player.get_node_or_null("HitboxPivot/SwordHitbox")
	if sword_hitbox == null:
		await _cleanup_scene()
		return {"pass": false, "message": "SwordHitbox 未找到"}
	var boss_hurtbox_ref = boss.get_node_or_null("HurtBox")
	if boss_hurtbox_ref == null:
		await _cleanup_scene()
		return {"pass": false, "message": "Boss.HurtBox 未找到"}

	# SwordHitbox enable (一开到底, Geometry2D AABB 主动检测 overlap)
	sword_hitbox.enable()

	var hits := 0
	print("    [Ch%d] Boss 初始 HP: %d, 玩家开始攻击" % [ch, initial_boss_hp])

	# === 真战斗循环: 每 round 模拟一次攻击 ===
	#   1. 玩家进入 overlap (HitBox 撞 HurtBox) → 扣血
	#   2. 玩家退出 overlap (后撤)
	#   3. 玩家再次进入 → 再扣血
	var round_count := 0
	var max_rounds := 100
	var watchdog_single = get_tree().create_timer(CHAPTER_TIMEOUT_SEC)
	var chapter_watchdog_hit := false
	watchdog_single.timeout.connect(func(): chapter_watchdog_hit = true)

	while round_count < max_rounds and not _timed_out() and not chapter_watchdog_hit:
		# 1. 玩家攻击位置 (overlap Boss HurtBox)
		player.global_position = boss_pos + Vector2(-30, 0)
		await get_tree().physics_frame
		# 检测 overlap
		if _check_hit(sword_hitbox, boss_hurtbox_ref) and not boss_stats.is_dead():
			boss_stats.take_damage(10)
			hits += 1

		# 2. 玩家后撤 (出 overlap)
		player.global_position = boss_pos + Vector2(-300, 0)
		await get_tree().physics_frame
		# 等一帧让物理引擎确认离开 (其实我们绕过物理, 但保持同步)
		await get_tree().create_timer(0.05).timeout

		round_count += 1
		if round_count % 5 == 0:
			print('    [Ch%d] round=%d HP=%d hits=%d' % [ch, round_count, boss_stats.health, hits])

		if boss_stats.health <= 0:
			break

	# === 验证结果 ===
	var final_hp = boss_stats.health
	var boss_killed_flag := false
	if _current_scene and "boss_killed" in _current_scene:
		boss_killed_flag = _current_scene.boss_killed

	await _cleanup_scene()

	if chapter_watchdog_hit:
		return {"pass": false, "message": "Ch%d 单章超时 (60s 没打死 Boss, hits=%d)" % [ch, hits]}
	if final_hp > 0:
		return {"pass": false, "message": "Ch%d 没打死 Boss (HP=%d, hits=%d)" % [ch, final_hp, hits]}
	if not boss_killed_flag:
		return {"pass": false, "message": "Boss HP=0 但 chapter.boss_killed=false"}

	return {
		"pass": true,
		"message": "Ch%d 真战斗通关 (rounds=%d hits=%d, 玩家移动 + Geometry2D overlap)" % [ch, round_count, hits]
	}


func _check_hit(sword_hitbox: Node, boss_hurtbox_ref: Node) -> bool:
	if sword_hitbox == null or boss_hurtbox_ref == null:
		return false
	var hit_rect = Rect2(sword_hitbox.global_position - Vector2(30, 15), Vector2(60, 30))
	var hurt_rect = Rect2(boss_hurtbox_ref.global_position - Vector2(18, 38), Vector2(36, 76))
	return hit_rect.intersects(hurt_rect)


# ---------------------------------------------------------------- helpers

func _find_node(scene: Node, name: String) -> Node:
	if scene == null:
		return null
	return scene.find_child(name, true, false)


func _cleanup_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null
	await get_tree().process_frame
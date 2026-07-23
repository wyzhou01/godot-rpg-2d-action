extends Node
## V2.6.C — 真玩家行为增强 (dodge 机制 + 物理护盾)
##
## 每个测试重新加载场景确保干净状态
## dash_duration = 0.2s = 12 帧, 测试必须在 dodge 期间读

const TestFramework = preload("res://tests/test_framework.gd")
const RobotPlayer = preload("res://scripts/testing/RobotPlayer.gd")

const BOSS_SCENE := "res://scenes/levels/chapter_1/chapter_1_boss.tscn"

var _tf: TestFramework
var _robot: RobotPlayer = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	_robot = RobotPlayer.new()
	add_child(_robot)
	# 把 Player 放到 root (离 Boss/Knight 远一些, 避免 HURT 干扰)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("player_behavior_advanced")

	# 每个测试加载新场景
	await _test_dodge_enter_invulnerable()
	await _test_dodge_velocity_dash_speed()
	await _test_dodge_exits_clears_invulnerable()
	await _test_idle_hurtbox_monitoring_active()

	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


# ===== helper =====

func _cleanup_scene(scene: Node) -> void:
	# Boss 在 root 时会主动攻击 Player, 因此 destroy 整个 root scene 树
	if scene and is_instance_valid(scene):
		scene.queue_free()
	_robot.release_all()
	await get_tree().process_frame


func _load_scene() -> Node:
	var scene: PackedScene = load(BOSS_SCENE)
	if scene == null:
		return null
	var inst: Node = scene.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	# Boss/Knight 不要. 删掉除 Player 外的所有 Boss/Enemy
	var boss_node := inst.find_child("Greyr1", true, false)
	if boss_node:
		boss_node.queue_free()
	var boss_minions := inst.find_child("BossEnemies", true, false)
	if boss_minions:
		boss_minions.queue_free()
	# Knight 在 BossEnemies 容器里, queue_free 后会消失
	await get_tree().process_frame
	# PauseMenu 也去掉避免干扰
	var pause := inst.find_child("PauseMenu", true, false)
	if pause:
		pause.queue_free()
	await get_tree().process_frame
	# 让玩家稳定
	for i in 3:
		await get_tree().physics_frame
	return inst


func _find_player(scene: Node) -> Node2D:
	if scene == null:
		return null
	return scene.find_child("Player", true, false)


func _send_dash(pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = "dash"
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# ===== tests =====

func _test_dodge_enter_invulnerable() -> void:
	var scene := await _load_scene()
	var player := _find_player(scene)
	if player == null:
		scene.queue_free()
		_tf.run_test("dodge 进 → invulnerable=true + monitoring=false", func() -> Dictionary:
			return {"pass": false, "message": "Player 不在"})
		return
	_robot.set_player(player)

	# 真按 dash
	_send_dash(true)
	# 等 3 帧: 1 帧 input 事件被处理 (just_pressed) + 1 帧 _state_idle 进 DODGE + 1 帧 _state_dodge 设 invulnerable=true
	await _wait_frames(3)

	var hurt_box: Node = player.get_node_or_null("HurtBox")
	if hurt_box == null:
		await _cleanup_scene(scene)
		_tf.run_test("dodge 进 → invulnerable=true + monitoring=false", func() -> Dictionary:
			return {"pass": false, "message": "HurtBox 不存在"})
		return

	var state_during: int = player.state
	var passed: bool = hurt_box.invulnerable == true and hurt_box.monitoring == false and state_during == 5
	var msg: String = "invul=%s monit=%s state=%d (期望 true/false/5=DODGE)" % [
		str(hurt_box.invulnerable), str(hurt_box.monitoring), state_during
	]
	_tf.run_test("dodge 进 → invulnerable=true + monitoring=false", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	# 释放 + 等 dodge 完成
	_send_dash(false)
	await _cleanup_scene(scene)


func _test_dodge_velocity_dash_speed() -> void:
	var scene := await _load_scene()
	var player := _find_player(scene)
	if player == null:
		scene.queue_free()
		_tf.run_test("dodge 期间 velocity = facing * dash_speed", func() -> Dictionary:
			return {"pass": false, "message": "Player 不在"})
		return
	_robot.set_player(player)

	_send_dash(true)
	# 等 3 帧让 _state_dodge 跑至少 1 次
	await _wait_frames(3)

	var state_during: int = player.state
	var velocity_x: float = player.velocity.x
	var facing: int = player.facing

	var passed: bool = state_during == 5 and abs(velocity_x) > 100.0
	var msg: String = "state=%d (期望 5=DODGE) vel.x=%.1f facing=%d" % [
		state_during, velocity_x, facing
	]
	_tf.run_test("dodge 期间 velocity = facing * dash_speed", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	_send_dash(false)
	await _cleanup_scene(scene)


func _test_dodge_exits_clears_invulnerable() -> void:
	var scene := await _load_scene()
	var player := _find_player(scene)
	if player == null:
		scene.queue_free()
		_tf.run_test("dodge 出 → invulnerable=false + can_dodge=false", func() -> Dictionary:
			return {"pass": false, "message": "Player 不在"})
		return
	_robot.set_player(player)

	_send_dash(true)
	# 等 20 帧 (>12 帧 dodge_duration + 余量)
	await _wait_frames(20)
	_send_dash(false)
	await _wait_frames(2)

	var hurt_box: Node = player.get_node_or_null("HurtBox")
	if hurt_box == null:
		await _cleanup_scene(scene)
		_tf.run_test("dodge 出 → invulnerable=false + can_dodge=false", func() -> Dictionary:
			return {"pass": false, "message": "HurtBox 不存在"})
		return

	var passed: bool = (
		hurt_box.invulnerable == false
		and hurt_box.monitoring == true
		and player.can_dodge == false
	)
	var msg: String = "invul=%s monit=%s can_dodge=%s state=%d (期望 false/true/false/0=IDLE)" % [
		str(hurt_box.invulnerable), str(hurt_box.monitoring), str(player.can_dodge), player.state
	]
	_tf.run_test("dodge 出 → invulnerable=false + can_dodge=false", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	await _cleanup_scene(scene)


func _test_idle_hurtbox_monitoring_active() -> void:
	var scene := await _load_scene()
	var player := _find_player(scene)
	if player == null:
		scene.queue_free()
		_tf.run_test("idle 时 HurtBox monitoring=true", func() -> Dictionary:
			return {"pass": false, "message": "Player 不在"})
		return

	# 不 dash — 玩家稳定 idle, 验证 baseline
	await _wait_frames(5)

	var hurt_box: Node = player.get_node_or_null("HurtBox")
	if hurt_box == null:
		await _cleanup_scene(scene)
		_tf.run_test("idle 时 HurtBox monitoring=true", func() -> Dictionary:
			return {"pass": false, "message": "HurtBox 不存在"})
		return

	var passed: bool = hurt_box.invulnerable == false and hurt_box.monitoring == true
	var msg: String = "invul=%s monit=%s (期望 false/true)" % [
		str(hurt_box.invulnerable), str(hurt_box.monitoring)
	]
	_tf.run_test("idle 时 HurtBox monitoring=true", func() -> Dictionary:
		return {"pass": passed, "message": msg})

	await _cleanup_scene(scene)
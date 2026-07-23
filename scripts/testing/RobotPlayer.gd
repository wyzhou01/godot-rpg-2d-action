extends Node
## 虚拟玩家 (V2.5)
##
## 通过 Input.action_press/release 真实驱动 Player 状态机
## 替代直接调方法/teleport/take_damage 绕过战斗系统
##
## 设计原则:
## - 不读/写 Player 内部状态 (除 Boss.HurtBox 等公开接口)
## - 用真 Input action, Player 自己 _read_input() 读到
## - 所有"等"操作基于 signal / health 变化 / 帧数 (非 magic sleep)
##
## 用法:
##   var robot = RobotPlayer.new()
##   add_child(robot)
##   await robot.move_to(target_position)
##   await robot.attack(times=3)
##   await robot.dash()
##   await robot.wait_for_boss_defeated()

class_name RobotPlayer

signal boss_defeated
signal player_died

var _player_path: NodePath
var _watchdog: SceneTreeTimer = null
var _watchdog_hit: bool = false


func _ready() -> void:
	pass


# ===== 公共 API =====

## 设置追踪的 Player 节点
func set_player(p: Node2D) -> void:
	if p:
		_player_path = NodePath()  # 清理
		# 直接存 Node2D 引用更稳
		_player = p


var _player: Node2D = null


func get_player() -> Node2D:
	return _player


## 等待 N 帧
func wait_frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


## 等待 N 个物理帧
func wait_physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


## 等待 T 秒 (基于 physics_frame, 不阻塞引擎)
func wait_seconds(t: float) -> void:
	var end_time := Time.get_ticks_msec() + int(t * 1000)
	while Time.get_ticks_msec() < end_time:
		await get_tree().physics_frame


## 持续按右键 (供 RUN 状态读到 move_right 强度 1.0)
## 会持续到调用 stop_move() 或 release_all()
func start_move_right() -> void:
	_press_action("move_right", 1.0, false)


func start_move_left() -> void:
	_press_action("move_left", 1.0, false)


func stop_move() -> void:
	_release_action("move_right", false)
	_release_action("move_left", false)


## 攻击一次 (is_action_just_pressed 需要在干净帧上 press)
## attack 触发后 Player._change_state(ATTACK) → 动画 attack_1 → on_finished → IDLE
## 一次完整攻击约 0.2-0.4s
func attack(times: int = 1) -> void:
	for i in range(times):
		await wait_physics_frames(1)  # 干净帧
		_press_action("attack", 1.0)
		await wait_physics_frames(1)  # 让 just_pressed 触发
		_release_action("attack")
		# 等动画完成 (attack_1 ≈ 0.25s)
		await wait_physics_frames(15)


## 跳跃一次
func jump() -> void:
	await wait_physics_frames(1)
	_press_action("jump", 1.0)
	await wait_physics_frames(1)
	_release_action("jump")
	await wait_physics_frames(20)


## 闪避
func dash() -> void:
	await wait_physics_frames(1)
	_press_action("dash", 1.0)
	await wait_physics_frames(1)
	_release_action("dash")
	await wait_physics_frames(15)


## 移动到目标 X 坐标 (沿当前 facing 或朝目标自动决定方向)
## 玩家在 ground 上, 持续按左右键直到 X 接近目标
func move_to_x(target_x: float, tolerance: float = 8.0, timeout_sec: float = 5.0) -> void:
	if _player == null:
		return
	var start_ticks := Time.get_ticks_msec()
	var timeout_ms := int(timeout_sec * 1000)
	while Time.get_ticks_msec() - start_ticks < timeout_ms:
		var dx := target_x - _player.global_position.x
		if abs(dx) < tolerance:
			stop_move()
			return
		if dx > 0:
			Input.action_press("move_right", 1.0)
			Input.action_release("move_left")
		else:
			Input.action_press("move_left", 1.0)
			Input.action_release("move_right")
		await get_tree().physics_frame
	stop_move()


## 等待 Boss 死亡 (Boss HP=0 或 scene boss_killed=true)
## timeout_sec 超时返回 false
func wait_for_boss_defeated(timeout_sec: float = 60.0) -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var boss := _find_boss_in_scene(scene)
	if boss == null:
		return false
	var boss_stats: Node = boss.get_node_or_null("Stats")
	if boss_stats == null:
		return false
	var start_ticks := Time.get_ticks_msec()
	var timeout_ms := int(timeout_sec * 1000)
	while Time.get_ticks_msec() - start_ticks < timeout_ms:
		await get_tree().physics_frame
		if boss_stats.health <= 0:
			boss_defeated.emit()
			return true
		if "boss_killed" in scene and scene.boss_killed:
			boss_defeated.emit()
			return true
	return false


## 等待 Player 死亡
func wait_for_player_death(timeout_sec: float = 60.0) -> bool:
	if _player == null:
		return false
	var stats: Node = _player.get_node_or_null("Stats")
	if stats == null:
		return false
	var start_ticks := Time.get_ticks_msec()
	var timeout_ms := int(timeout_sec * 1000)
	while Time.get_ticks_msec() - start_ticks < timeout_ms:
		await get_tree().physics_frame
		if stats.health <= 0 or stats.is_dead():
			player_died.emit()
			return true
	return false


## 等待 HP 变化 (用于判定"被击中")
## 返回变化量 (可能为负)
func wait_for_health_change(timeout_sec: float = 5.0) -> float:
	if _player == null:
		return 0.0
	var stats: Node = _player.get_node_or_null("Stats")
	if stats == null:
		return 0.0
	var start_hp: float = stats.health
	var start_ticks := Time.get_ticks_msec()
	var timeout_ms := int(timeout_sec * 1000)
	while Time.get_ticks_msec() - start_ticks < timeout_ms:
		await get_tree().physics_frame
		if stats.health != start_hp:
			return stats.health - start_hp
	return 0.0


## 释放所有按下的输入 (测试结束前必调)
func release_all() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "attack", "shield", "war_cry", "heal", "ultimate", "interact", "pause"]:
		Input.action_release(action)


# ===== Input helpers =====

## 真 input: 送 InputEventAction 进 input 系统, 触发 is_action_just_pressed
## headless 下 Input.action_press 不一定能触发 just_pressed 机制 (依赖 InputEvent 流程)
func _press_action(action: String, strength: float = 1.0, trigger_just_pressed: bool = true) -> void:
	if trigger_just_pressed:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = true
		ev.strength = strength
		Input.parse_input_event(ev)
	else:
		Input.action_press(action, strength)


func _release_action(action: String, trigger_just_pressed: bool = true) -> void:
	if trigger_just_pressed:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = false
		Input.parse_input_event(ev)
	else:
		Input.action_release(action)


# ===== helpers =====

func _find_boss_in_scene(scene: Node) -> Node:
	# 已知 Boss 节点名
	for name in ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx"]:
		var n := scene.find_child(name, true, false)
		if n:
			return n
	return null
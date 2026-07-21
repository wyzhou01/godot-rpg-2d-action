class_name BaseBoss extends CharacterBody2D
## Boss 基类（简单 if/else 状态机，多阶段）
##
## 关键设计:
##   - 不用 Beehave（因为 Beehave addons 与 Godot 4.6 .uid 不兼容）
##   - 改用基类 _physics_process 中 switch state
##   - 子类通过重写 _ai_tick(delta) 自定义行为
##
## 节点结构:
##   Boss (CharacterBody2D, 挂 BaseBoss.gd)
##   ├── Sprite2D (ColorRect 占位)
##   ├── CollisionShape2D
##   ├── Stats (Node, 挂 Stats.gd)
##   ├── HurtBox (Area2D, 挂 HurtBox.gd)
##   ├── PlayerDetectionZone (Area2D, 挂 PlayerDetectionZone.gd)
##   ├── AnimationPlayer
##   └── (可选) ProjectileSpawner

@export var boss_stats: BossStats
@export var move_speed: float = 80.0
@export var gravity: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox
@onready var detection: PlayerDetectionZone = $PlayerDetectionZone
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _safe_play(anim_name: String) -> void:
	# Bug 修复: AnimationPlayer 节点存在但无动画时 (项目内 7 个 Boss tscn 都是空库),
	# 直接 play 会 ERROR print 一堆 "Animation not found"。
	# has_animation 检查后才播，避免噪音日志。
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

enum BossState { IDLE, CHASE, ATTACK, HURT, DEATH }
var state: BossState = BossState.IDLE
var current_phase: int = 1  # 1/2/3
var facing: int = 1
var player_ref: Node2D = null
var _attack_timer: float = 0.0
var _shoot_timer: float = 0.0
var _summon_timer: float = 0.0


func _ready() -> void:
	add_to_group("boss")
	_setup_stats()
	_setup_signals()
	_check_phase_transition()


func _setup_stats() -> void:
	if boss_stats:
		stats.max_health = boss_stats.max_hp


func _setup_signals() -> void:
	stats.health_decreased_but_not_depleted.connect(_on_hurt)
	stats.health_decreased_and_depleted.connect(_on_defeated)
	if detection:
		detection.player_detected.connect(_on_player_detected)


func _physics_process(delta: float) -> void:
	if state == BossState.DEATH:
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	if detection:
		player_ref = detection.player

	_check_phase_transition()

	# 攻击/技能冷却
	if _attack_timer > 0:
		_attack_timer -= delta
	if _shoot_timer > 0:
		_shoot_timer -= delta
	if _summon_timer > 0:
		_summon_timer -= delta

	# AI 状态机（子类可重写 _ai_tick）
	_ai_tick(delta)

	velocity.x = move_toward(velocity.x, 0, 200 * delta)
	move_and_slide()
	_update_sprite_direction()


## 子类重写：实现具体 AI 行为
func _ai_tick(_delta: float) -> void:
	# 默认：追踪玩家
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return
	var distance = global_position.distance_to(p.global_position)
	if distance > 80.0:
		state = BossState.CHASE
		move_toward_player(move_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(15)
		_attack_timer = 1.5
	else:
		state = BossState.IDLE


# ===== 工具函数（行为树 Action 调用） =====
func get_player() -> Node2D:
	if detection and detection.player:
		return detection.player
	return null


func is_player_in_range(range: float = 80.0) -> bool:
	var p = get_player()
	if not is_instance_valid(p):
		return false
	return global_position.distance_to(p.global_position) <= range


func move_toward_player(speed: float = 80.0) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		return
	var direction = sign(p.global_position.x - global_position.x)
	facing = int(direction)
	velocity.x = direction * speed


func attack_player(damage: int) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		return
	var p_stats = p.get_node_or_null("Stats")
	if p_stats:
		p_stats.take_damage(damage)


func shoot_at_player(damage: int = 8, speed: float = 600.0) -> bool:
	var spawner = get_node_or_null("ProjectileSpawner")
	var p = get_player()
	if not spawner or not is_instance_valid(p):
		return false
	var arrow_scene = load("res://scenes/characters/projectiles/arrow.tscn")
	if arrow_scene == null:
		return false
	var arrow = arrow_scene.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = spawner.global_position
	var direction = (p.global_position - arrow.global_position).normalized()
	direction.y = 0
	direction = direction.normalized()
	if arrow.has_method("initialize"):
		arrow.initialize(direction, speed)
		arrow.attacker = self
		arrow.damage = damage
	return true


func summon_knight() -> bool:
	var p = get_player()
	if not is_instance_valid(p):
		return false
	var knight_scene = load("res://scenes/characters/enemies/knight.tscn")
	if knight_scene == null:
		return false
	var knight = knight_scene.instantiate()
	get_parent().add_child(knight)
	var behind = -sign(p.velocity.x) if abs(p.velocity.x) > 1 else sign(global_position.x - p.global_position.x)
	knight.global_position = p.global_position + Vector2(behind * 80.0, 0)
	return true


# ===== 阶段切换 =====
func _check_phase_transition() -> void:
	if not boss_stats:
		return
	var hp_percent = stats.get_health_percent()
	var new_phase = current_phase
	if hp_percent <= boss_stats.phase_3_threshold and current_phase < 3:
		new_phase = 3
	elif hp_percent <= boss_stats.phase_2_threshold and current_phase < 2:
		new_phase = 2
	if new_phase != current_phase:
		_on_phase_changed(new_phase)


func _on_phase_changed(new_phase: int) -> void:
	current_phase = new_phase


# ===== 信号回调 =====
func _on_hurt() -> void:
	_safe_play("hurt")
	velocity.x = facing * -200


func _on_defeated() -> void:
	state = BossState.DEATH
	_safe_play("death")
	set_physics_process(false)
	_trigger_post_battle_dialogue()
	get_tree().create_timer(2.0).timeout.connect(queue_free)


func _trigger_post_battle_dialogue() -> void:
	pass  # 子类实现


func _on_player_detected(p: Node2D) -> void:
	player_ref = p


func _update_sprite_direction() -> void:
	if velocity.x > 0:
		sprite.scale.x = 1
		facing = 1
	elif velocity.x < 0:
		sprite.scale.x = -1
		facing = -1


func play_anim(anim_name: String) -> void:
	_safe_play(anim_name)

class_name BaseEnemy extends CharacterBody2D
## 敌人基类（HeartBeast 模式 + enum 状态机）
##
## 节点结构 (BaseEnemy.tscn):
##   Enemy (CharacterBody2D, 挂 BaseEnemy.gd)
##   ├── AnimatedSprite2D
##   ├── CollisionShape2D
##   ├── Stats (Node, 挂 Stats.gd)
##   ├── HurtBox (Area2D, 挂 HurtBox.gd)
##   ├── PlayerDetectionZone (Area2D, 挂 PlayerDetectionZone.gd)
##   ├── AnimationPlayer
##   └── (optional) ProjectileSpawner (Node2D, 远程敌人)

# 状态枚举
enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEATH,
}

@export var enemy_stats: EnemyStats
@export var move_speed: float = 60.0
@export var gravity: float = 1200.0

# 节点引用
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox
@onready var detection: PlayerDetectionZone = $PlayerDetectionZone
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state: State = State.IDLE
var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var facing: int = 1  # 1 = 右, -1 = 左


func _ready() -> void:
	add_to_group("enemy")
	_setup_stats()
	_setup_signals()


func _setup_stats() -> void:
	if enemy_stats:
		stats.max_health = enemy_stats.max_hp


func _setup_signals() -> void:
	stats.health_decreased_but_not_depleted.connect(_on_hurt)
	stats.health_decreased_and_depleted.connect(_on_death)
	if detection:
		detection.player_detected.connect(_on_player_detected)
		detection.player_lost.connect(_on_player_lost)


func _physics_process(delta: float) -> void:
	if state == State.DEATH:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.IDLE: _state_idle(delta)
		State.CHASE: _state_chase(delta)
		State.ATTACK: _state_attack(delta)
		State.HURT: pass

	move_and_slide()
	_update_sprite_direction()


# ===== 状态实现 =====
func _state_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 300 * _delta)
	play_anim("idle")
	if detection and detection.has_player():
		player = detection.player
		_change_state(State.CHASE)


func _state_chase(_delta: float) -> void:
	if not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	play_anim("run")
	if distance_to_player <= (enemy_stats.attack_range if enemy_stats else 100.0):
		_change_state(State.ATTACK)
	else:
		var direction = sign(player.global_position.x - global_position.x)
		facing = int(direction)
		velocity.x = direction * move_speed


func _state_attack(_delta: float) -> void:
	velocity.x = 0
	play_anim("attack")
	# 实际攻击由动画驱动（attack hitbox 启用/禁用）
	if not is_instance_valid(player):
		_change_state(State.IDLE)


# ===== 信号回调 =====
func _on_hurt() -> void:
	_change_state(State.HURT)
	play_anim("hurt")
	# 击退（如果 HitBox 有 knockback_direction）
	velocity.x = facing * -150  # 默认后退


func _on_death() -> void:
	_change_state(State.DEATH)
	play_anim("death")
	# 死亡特效
	set_physics_process(false)
	# 一段时间后销毁
	get_tree().create_timer(1.0).timeout.connect(queue_free)


func _on_player_detected(p: Node2D) -> void:
	player = p


func _on_player_lost(_p: Node2D) -> void:
	player = null
	if state == State.CHASE:
		_change_state(State.IDLE)


# ===== 状态切换 =====
func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state


# ===== 动画 =====
func play_anim(name: String) -> void:
	if animation_player and animation_player.current_animation != name:
		animation_player.play(name)


# ===== 方向 =====
func _update_sprite_direction() -> void:
	if velocity.x > 0:
		sprite.flip_h = false
		facing = 1
	elif velocity.x < 0:
		sprite.flip_h = true
		facing = -1


# AnimationPlayer 动画结束回调（子类可重写）
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"attack":
		if detection and detection.has_player():
			var dist = global_position.distance_to(player.global_position)
			if dist > (enemy_stats.attack_range if enemy_stats else 100.0):
				_change_state(State.CHASE)
		else:
			_change_state(State.IDLE)
	elif anim_name == &"hurt":
		if detection and detection.has_player():
			_change_state(State.CHASE)
		else:
			_change_state(State.IDLE)

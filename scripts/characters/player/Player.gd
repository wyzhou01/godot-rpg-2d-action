class_name Player extends CharacterBody2D
## 玩家主控制器（HeartBeast 模式 + enum 状态机）
##
## 节点结构 (Player.tscn):
##   Player (CharacterBody2D, 挂 Player.gd)
##   ├── AnimatedSprite2D
##   ├── CollisionShape2D
##   ├── Stats (Node, 挂 Stats.gd)
##   ├── HurtBox (Area2D, 挂 HurtBox.gd)
##   ├── HitboxPivot (Node2D, 旋转决定攻击方向)
##   │   └── SwordHitbox (Area2D, 挂 SwordHitbox.gd)
##   │       └── CollisionShape2D
##   ├── StateMachine (Node, 挂 PlayerStateMachine.gd)
##   ├── AnimationPlayer
##   └── PlayerDetectionZone (Area2D)  # 玩家无需此，但保留可扩展

# 状态枚举
enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	DODGE,
	HURT,
	DEATH,
}

@export var player_stats: PlayerStats
@export var enemy_stats: Resource  # 复用 stats 系统的灵活性

# 节点引用（场景树）
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox
@onready var hitbox_pivot: Node2D = $HitboxPivot
@onready var sword_hitbox: HitBox = $HitboxPivot/SwordHitbox
# 可选节点（场景可能未挂载，运行时 null-safe）
@onready var state_machine: Node = get_node_or_null("StateMachine")
@onready var player_detection_zone: Area2D = get_node_or_null("PlayerDetectionZone")

# 状态机
var state: PlayerState = PlayerState.IDLE

# 输入缓存
var input_direction: float = 0.0
var input_jump_pressed: bool = false
var input_attack_pressed: bool = false
var input_dodge_pressed: bool = false

# 物理
var gravity: float = 1200.0
var facing: int = 1  # 1 = 右, -1 = 左

# 战斗
var attack_combo_index: int = 0
var attack_combo_window_timer: float = 0.0
var can_combo: bool = false

# 闪避
var dodge_timer: float = 0.0
var can_dodge: bool = true


func _ready() -> void:
	add_to_group("player")
	if state_machine:
		state_machine.current_state = "Idle"
	_setup_animations()
	_setup_signals()


func _setup_animations() -> void:
	# 连接 AnimatedSprite2D 信号
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)


func _setup_signals() -> void:
	stats.health_decreased_and_depleted.connect(_on_death)
	stats.health_decreased_but_not_depleted.connect(_on_hurt)
	# 应用 player_stats 配置
	if player_stats:
		stats.max_health = player_stats.max_hp


func _physics_process(delta: float) -> void:
	if state == PlayerState.DEATH:
		return

	# 读取输入
	_read_input()

	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta

	# 状态机更新
	match state:
		PlayerState.IDLE: _state_idle(delta)
		PlayerState.RUN: _state_run(delta)
		PlayerState.JUMP: _state_jump(delta)
		PlayerState.FALL: _state_fall(delta)
		PlayerState.ATTACK: _state_attack(delta)
		PlayerState.DODGE: _state_dodge(delta)
		PlayerState.HURT: _state_hurt(delta)

	# 连击窗口计时
	if attack_combo_window_timer > 0:
		attack_combo_window_timer -= delta
		if attack_combo_window_timer <= 0:
			attack_combo_index = 0
			can_combo = false

	# 闪避冷却
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			can_dodge = true

	move_and_slide()
	_update_sprite_direction()


# ===== 输入 =====
func _read_input() -> void:
	input_direction = Input.get_axis("move_left", "move_right")
	input_jump_pressed = Input.is_action_just_pressed("jump")
	input_attack_pressed = Input.is_action_just_pressed("attack")
	input_dodge_pressed = Input.is_action_just_pressed("dash")


# ===== 状态实现 =====
func _state_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, player_stats.move_speed * 5 * _delta if player_stats else 1100 * _delta)
	play_anim("idle")
	if input_direction != 0:
		_change_state(PlayerState.RUN)
	elif input_jump_pressed and is_on_floor():
		_change_state(PlayerState.JUMP)
	elif input_attack_pressed:
		_change_state(PlayerState.ATTACK)
	elif input_dodge_pressed and can_dodge:
		_change_state(PlayerState.DODGE)


func _state_run(delta: float) -> void:
	if input_direction != 0:
		velocity.x = input_direction * (player_stats.move_speed if player_stats else 220.0)
	else:
		_change_state(PlayerState.IDLE)
		return
	play_anim("run")
	if not is_on_floor():
		_change_state(PlayerState.FALL)
	elif input_jump_pressed:
		_change_state(PlayerState.JUMP)
	elif input_attack_pressed:
		_change_state(PlayerState.ATTACK)
	elif input_dodge_pressed and can_dodge:
		_change_state(PlayerState.DODGE)


func _state_jump(delta: float) -> void:
	if state != PlayerState.JUMP or not has_jumped:
		# 第一次进入
		velocity.y = (player_stats.jump_velocity if player_stats else -480.0)
		has_jumped = true
	play_anim("jump")
	if velocity.y > 0:
		_change_state(PlayerState.FALL)
	elif input_attack_pressed and attack_combo_index == 0:
		_change_state(PlayerState.ATTACK)
	# 空中可控制方向
	if input_direction != 0:
		velocity.x = input_direction * (player_stats.move_speed if player_stats else 220.0)


func _state_fall(delta: float) -> void:
	play_anim("fall")
	if is_on_floor():
		has_jumped = false
		_change_state(PlayerState.IDLE if input_direction == 0 else PlayerState.RUN)
	# 空中攻击（下落斩）
	if input_attack_pressed and attack_combo_index == 0:
		_change_state(PlayerState.ATTACK)


func _state_attack(delta: float) -> void:
	# 攻击时不能动，但保持当前动画
	velocity.x = move_toward(velocity.x, 0, (player_stats.move_speed if player_stats else 220.0) * 5 * delta)
	match attack_combo_index:
		0: play_anim("attack_1")
		1: play_anim("attack_2")
		2: play_anim("attack_3")


func _state_dodge(delta: float) -> void:
	# 闪避时无敌
	hurt_box.invulnerable = true
	velocity.x = facing * (player_stats.dash_speed if player_stats else 480.0)
	play_anim("dodge")


func _state_hurt(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 800 * _delta)
	play_anim("hurt")


var has_jumped: bool = false

func _change_state(new_state: PlayerState) -> void:
	if state == new_state:
		return
	# 退出当前状态
	match state:
		PlayerState.DODGE:
			hurt_box.invulnerable = false
		PlayerState.ATTACK:
			sword_hitbox.disable()
	state = new_state
	# 进入新状态
	match new_state:
		PlayerState.JUMP:
			has_jumped = false
		PlayerState.ATTACK:
			attack_combo_index = 0
			can_combo = false
			attack_combo_window_timer = 0.0
		PlayerState.DODGE:
			can_dodge = false
			dodge_timer = (player_stats.dash_cooldown if player_stats else 1.0)


# ===== 动画信号回调 =====
func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"attack_1":
			if can_combo:
				attack_combo_index = 1
				attack_combo_window_timer = (player_stats.attack_combo_window if player_stats else 0.15)
				sword_hitbox.disable()
				play_anim("attack_2")
				_enable_attack_hitbox()
			else:
				attack_combo_index = 0
				sword_hitbox.disable()
				_change_state(PlayerState.IDLE)
		&"attack_2":
			if can_combo:
				attack_combo_index = 2
				attack_combo_window_timer = (player_stats.attack_combo_window if player_stats else 0.15)
				sword_hitbox.disable()
				play_anim("attack_3")
				_enable_attack_hitbox()
			else:
				attack_combo_index = 0
				sword_hitbox.disable()
				_change_state(PlayerState.IDLE)
		&"attack_3":
			attack_combo_index = 0
			sword_hitbox.disable()
			_change_state(PlayerState.IDLE)
		&"dodge":
			hurt_box.invulnerable = false
			_change_state(PlayerState.IDLE)
		&"hurt":
			_change_state(PlayerState.IDLE)


## AnimationPlayer 的方法 track 在 attack_1 中调用，启用 HitBox
func _enable_attack_hitbox() -> void:
	sword_hitbox.enable()
	can_combo = true  # 允许接第二段


## AnimationPlayer 的方法 track 在 attack_1 结束前调用，检查是否可以接招
func _check_combo() -> void:
	pass  # 在 on_animation_finished 里处理


func play_anim(name: String) -> void:
	if sprite and sprite.animation != name:
		sprite.play(name)


# ===== 信号回调 =====
func _on_hurt() -> void:
	_change_state(PlayerState.HURT)
	play_anim("hurt")


func _on_death() -> void:
	_change_state(PlayerState.DEATH)
	play_anim("death")
	set_physics_process(false)


# ===== 工具 =====
func _update_sprite_direction() -> void:
	if velocity.x > 0:
		facing = 1
		sprite.scale.x = -1
		hitbox_pivot.scale.x = 1
	elif velocity.x < 0:
		facing = -1
		sprite.scale.x = 1
		hitbox_pivot.scale.x = -1

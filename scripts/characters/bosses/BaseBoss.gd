class_name BaseBoss extends CharacterBody2D
## Boss 基类（多阶段机制 + Beehave 行为树）
##
## 关键设计:
##   - 多阶段通过 HP 阈值切换（phase_2_threshold / phase_3_threshold）
##   - 行为树（Beehave）控制 AI，每个阶段不同技能组合
##   - 战前/战后用 Dialogic 触发对话
##
## 节点结构:
##   Boss (CharacterBody2D, 挂 BaseBoss.gd)
##   ├── AnimatedSprite2D
##   ├── CollisionShape2D
##   ├── Stats (Node, 挂 Stats.gd)
##   ├── HurtBox (Area2D, 挂 HurtBox.gd)
##   ├── PlayerDetectionZone (Area2D, 挂 PlayerDetectionZone.gd)
##   ├── AnimationPlayer
##   ├── BeehaveTree (Node, 挂 Beehave v2.9.3)
##   │   └── SelectorComposite (顶层选择器)
##   │       └── Sequence: Phase 1 (满血)
##   │       └── Sequence: Phase 2 (< 66% HP)
##   │       └── Sequence: Phase 3 (< 33% HP, rage)
##   └── (可选) ProjectileSpawner

@export var boss_stats: BossStats
@export var move_speed: float = 80.0
@export var gravity: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox
@onready var detection: PlayerDetectionZone = $PlayerDetectionZone
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var beehave_tree: Node = $BeehaveTree

var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var facing: int = 1
var current_phase: int = 1  # 1/2/3

signal phase_changed(new_phase)
signal boss_defeated
signal dialogue_triggered(timeline: String)


func _ready() -> void:
	add_to_group("boss")
	_setup_stats()
	_setup_signals()
	_setup_beehave()


func _setup_stats() -> void:
	if boss_stats:
		stats.max_health = boss_stats.max_hp


func _setup_signals() -> void:
	stats.health_decreased_but_not_depleted.connect(_on_hurt)
	stats.health_decreased_and_depleted.connect(_on_defeated)
	if detection:
		detection.player_detected.connect(_on_player_detected)


func _setup_beehave() -> void:
	# Beehave 自动运行（在 _ready 里调用 tick）
	# 但行为树的状态变化需要重新启用对应子树
	pass


func _physics_process(delta: float) -> void:
	if current_phase == 3 and stats.is_dead():
		return

	_check_phase_transition()

	if not is_on_floor():
		velocity.y += gravity * delta

	_update_ai(delta)

	move_and_slide()
	_update_sprite_direction()


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
	phase_changed.emit(new_phase)
	# 触发阶段切换动画
	play_anim("phase_transition")
	# 切换 Beehave 行为树子树（需要 Godot 编辑器配置）
	push_warning("Boss 阶段切换到 %d - 需要手动配置行为树" % new_phase)


# ===== AI 更新（默认实现，子类可重写） =====
func _update_ai(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	# 默认 AI：追踪玩家
	var direction = sign(player.global_position.x - global_position.x)
	facing = int(direction)
	velocity.x = direction * move_speed
	play_anim("walk")


# ===== 信号回调 =====
func _on_hurt() -> void:
	play_anim("hurt")
	velocity.x = facing * -200  # 击退


func _on_defeated() -> void:
	current_phase = 3
	play_anim("death")
	set_physics_process(false)
	boss_defeated.emit()
	# 触发战后对话（子类可重写）
	_trigger_post_battle_dialogue()
	# 一段时间后销毁
	get_tree().create_timer(2.0).timeout.connect(queue_free)


func _trigger_post_battle_dialogue() -> void:
	# 子类实现：调用 Dialogic.start(timeline)
	pass


func _on_player_detected(p: Node2D) -> void:
	player = p


# ===== 工具 =====
func play_anim(name: String) -> void:
	if animation_player and animation_player.current_animation != name:
		animation_player.play(name)


func _update_sprite_direction() -> void:
	if velocity.x > 0:
		sprite.flip_h = false
		facing = 1
	elif velocity.x < 0:
		sprite.flip_h = true
		facing = -1

class_name Archer extends BaseEnemy
## 远程弓箭手
##
## 行为:
##   - 检测到玩家 → 停下
##   - 持续射击（按 attack_cooldown）
##   - 玩家离开 → 重新 chase
##
## 节点结构:
##   Archer (CharacterBody2D, 挂 Archer.gd)
##   ├── (BaseEnemy 节点)
##   ├── ProjectileSpawner (Node2D, 朝玩家方向)
##   │   └── ProjectileSpawnPoint (Marker2D)

@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 1.5

@onready var projectile_spawner: Node2D = $ProjectileSpawner

var attack_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("archer")
	if enemy_stats:
		attack_cooldown = enemy_stats.attack_cooldown


func _state_chase(_delta: float) -> void:
	if not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	# 弓箭手在远处停下
	if distance_to_player <= (enemy_stats.attack_range if enemy_stats else 500.0):
		# 进入攻击范围停下
		velocity.x = 0
		play_anim("idle")
		# 朝向玩家
		facing = int(sign(player.global_position.x - global_position.x))
		_update_sprite_direction()
		# 倒计时攻击
		attack_timer -= _physics_delta
		if attack_timer <= 0:
			_shoot_arrow()
			attack_timer = attack_cooldown
	else:
		# 距离太远，靠近
		var direction = sign(player.global_position.x - global_position.x)
		facing = int(direction)
		velocity.x = direction * move_speed
		play_anim("run")


var _physics_delta: float = 0.0

func _physics_process(delta: float) -> void:
	_physics_delta = delta
	super._physics_process(delta)


func _shoot_arrow() -> void:
	if projectile_scene == null:
		push_warning("Archer: projectile_scene not set")
		return

	var arrow = projectile_scene.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = projectile_spawner.global_position

	# 计算方向（朝玩家，但保持水平）
	var direction = Vector2.RIGHT if facing > 0 else Vector2.LEFT
	if is_instance_valid(player):
		direction = (player.global_position - arrow.global_position).normalized()
		direction.y = 0  # 保持水平飞行
		direction = direction.normalized()

	if arrow.has_method("initialize"):
		var speed = enemy_stats.projectile_speed if enemy_stats else 600.0
		arrow.initialize(direction, speed)
		arrow.attacker = self


func _on_player_lost(_p: Node2D) -> void:
	super._on_player_lost(_p)
	attack_timer = 0.0

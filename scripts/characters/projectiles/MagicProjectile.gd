class_name MagicProjectile extends Area2D
## 法师射出的魔法弹（可斜飞）

var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var attacker: Node = null
var damage: int = 2
var lifetime: float = 4.0


func _ready() -> void:
	collision_layer = 8  # ENEMY_ATTACK
	collision_mask = 4   # PLAYER_HURTBOX
	area_entered.connect(_on_area_entered)
	# 紫色拖尾粒子（待添加）


func initialize(dir: Vector2, spd: float) -> void:
	direction = dir.normalized()
	speed = spd
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not (area is HurtBox):
		return
	var hurt_box = area as HurtBox
	var stats = hurt_box.stats
	if stats:
		stats.take_damage(damage)
	queue_free()

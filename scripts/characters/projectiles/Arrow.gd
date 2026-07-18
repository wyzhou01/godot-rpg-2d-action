class_name Arrow extends Area2D
## 弓箭手射出的箭（直线飞行 + HitBox 逻辑）

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var attacker: Node = null
var damage: int = 1
var lifetime: float = 3.0


func _ready() -> void:
	collision_layer = 8  # ENEMY_ATTACK
	collision_mask = 4   # 检测 PLAYER_HURTBOX
	area_entered.connect(_on_area_entered)


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
	if area is HitBox:
		return  # 箭不会击中其他 HitBox
	if not (area is HurtBox):
		return
	var hurt_box = area as HurtBox
	var stats = hurt_box.stats
	if stats:
		stats.take_damage(damage)
	queue_free()

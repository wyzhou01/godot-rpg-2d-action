extends CharacterBody2D
class_name Actor
## 所有角色的基类（Player/Enemy/Boss 统一接口）
##
## 节点结构 (Actor.tscn):
##   Actor (CharacterBody2D, 挂 Actor.gd)
##   ├── AnimatedSprite2D
##   ├── CollisionShape2D
##   ├── Stats (Node, 挂 Stats.gd)
##   ├── HurtBox (Area2D)
##   ├── HitBoxPivot (Node2D, 攻击方向)
##   │   └── SwordHitbox (Area2D)
##   └── AnimationPlayer

@export var speed: Vector2 = Vector2(200.0, 500.0)
@export var gravity: float = 1500.0

var _velocity: Vector2 = Vector2.ZERO
var _facing: int = 1  # 1=右, -1=左

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox


func _physics_process(delta: float) -> void:
	# 应用重力
	if not is_on_floor():
		_velocity.y += gravity * delta


## 简单移动（带 snap 用于平台游戏）
func move(snap: Vector2 = Vector2.ZERO) -> void:
	_velocity = move_and_slide_with_snap(_velocity, snap, Vector2.UP, true)


## 撞墙反弹（敌人用）
func move_and_bounce() -> void:
	_velocity = move_and_slide(_velocity, Vector2.UP)
	if is_on_wall():
		_velocity.x *= -1
		_facing = -_facing


## 设置水平速度（外部用）
func set_velocity_x(vx: float) -> void:
	_velocity.x = vx
	if vx > 0:
		_facing = 1
	elif vx < 0:
		_facing = -1


## 朝向（1=右, -1=左）
func get_facing() -> int:
	return _facing


## 死亡
func die() -> void:
	# 子类重写
	pass
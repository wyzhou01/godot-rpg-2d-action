class_name HitBox extends Area2D
## 攻击碰撞区域
## 用法: 挂在攻击者上（如 Player 下的 HitboxPivot/SwordHitbox）
##
## 关键设计: 通过 collision_layer/mask 与 HurtBox 配对
##   - HitBox 默认 layer=4 (PLAYER_ATTACK), mask=4 (ENEMY_HURTBOX)
##   - HurtBox 默认 layer=2 (ENEMY_HURTBOX), mask=4 (PLAYER_ATTACK)
##   - 这样玩家攻击只能命中敌人受击区，反之亦然
##
## 子类: SwordHitbox 可加击退方向

# Collision Layer 常量
const LAYER_PLAYER_ATTACK := 4
const LAYER_ENEMY_ATTACK := 8
const LAYER_BOSS_ATTACK := 16

# Collision Mask 常量
const MASK_PLAYER_ATTACK := 4
const MASK_ENEMY_ATTACK := 8
const MASK_BOSS_ATTACK := 16

@export var damage: int = 10
@export var knockback_force: float = 200.0
@export var knockback_direction: Vector2 = Vector2.RIGHT
## 击中后是否销毁（用于一次性弹幕/陷阱）
@export var destroy_on_hit: bool = false
## 攻击者引用（用于追踪伤害来源）
var attacker: Node = null


func _ready() -> void:
	# 默认配对（玩家攻击 -> 敌人受击）
	if collision_layer == 0:
		collision_layer = LAYER_PLAYER_ATTACK
	if collision_mask == 0:
		collision_mask = MASK_PLAYER_ATTACK


## 启用攻击窗口（动画用）
func enable() -> void:
	monitoring = true
	# 同时启用 CollisionShape2D — 没有这个 shape 等于不参与碰撞，area_entered 永不触发
	# Bug 修复: 原版只开 monitoring 不开 shape，导致玩家始终打不到敌人
	for shape in get_children():
		if shape is CollisionShape2D:
			shape.disabled = false


## 禁用攻击窗口（动画用）
func disable() -> void:
	monitoring = false
	for shape in get_children():
		if shape is CollisionShape2D:
			shape.disabled = true

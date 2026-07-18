class_name HurtBox extends Area2D
## 受击碰撞区域（自动检测 HitBox 进入并扣血）
## 用法: 挂在角色身上（Player / Enemy / Boss 都有）
##
## 关键设计: 自动订阅 Stats 节点的信号
##   - 找到父节点的 Stats 子节点
##   - 不需要任何手动 take_damage() 调用
##
## 子类可重写 _on_hit() 添加额外逻辑（击退 / 硬直 / 闪避）

# Collision Layer 常量
const LAYER_PLAYER_HURTBOX := 2
const LAYER_ENEMY_HURTBOX := 2
const LAYER_BOSS_HURTBOX := 32

# Collision Mask 常量
const MASK_PLAYER_ATTACK := 4
const MASK_ENEMY_ATTACK := 8
const MASK_BOSS_ATTACK := 16

@export var disable_invulnerable_after_hit: bool = false
## 是否免疫伤害（用于教程/无敌帧期间）
@export var invulnerable: bool = false:
	set(value):
		invulnerable = value
		monitoring = not value  # 无敌时禁用检测

var stats: Stats = null
var owner_node: Node = null  # 拥有这个 HurtBox 的角色


func _ready() -> void:
	# 默认配对（敌人受击区检测玩家攻击）
	if collision_layer == 0:
		collision_layer = LAYER_ENEMY_HURTBOX
	if collision_mask == 0:
		collision_mask = MASK_PLAYER_ATTACK

	# 自动找到父节点的 Stats
	owner_node = get_parent()
	if owner_node:
		stats = owner_node.get_node_or_null("Stats")
		if stats == null:
			push_warning("HurtBox: parent has no Stats node. Owner: " + owner_node.name)

	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if invulnerable:
		return
	if not (area is HitBox):
		return
	if stats == null:
		return

	# 防止自己人打自己人
	if area.attacker == owner_node:
		return

	# 防止同一 HitBox 多次扣血（如果 HitBox 在攻击窗口内多次 area_entered）
	if not stats.is_dead():
		stats.take_damage(area.damage)
		_on_hit(area)

	# 一次性弹幕
	if area.destroy_on_hit:
		area.queue_free()


## 子类可重写：添加击退、硬直等逻辑
func _on_hit(_hit_box: HitBox) -> void:
	pass


## 设置无敌帧持续时间（需要外部调用 reset_invulnerable）
func set_invulnerable(duration: float) -> void:
	invulnerable = true
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		invulnerable = false
	)

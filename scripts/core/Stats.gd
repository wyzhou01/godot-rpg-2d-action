class_name Stats extends Node
## 通用 HP 管理节点 + 信号机制
## 用法: 挂在角色节点下，命名为 Stats
##
## 信号:
##   health_decreased_and_depleted - HP 归零
##   health_decreased_but_not_depleted - 受击但没死
##   health_increased - 治疗
##
## 示例:
##   @onready var stats: Stats = $Stats
##   stats.health_decreased_but_not_depleted.connect(_on_hurt)
##   stats.health_decreased_and_depleted.connect(_on_death)

signal health_decreased_and_depleted
signal health_decreased_but_not_depleted
signal health_increased

@export var max_health: int = 100

var health: int:
	set(value):
		var prev = health
		var new_value = clampi(value, 0, max_health)
		# Bug 修复: 保存 prev 在赋值前（但 prev 已读旧值）
		# 实际 GDScript 中 prev = health 读的是当前值（赋值前），正确
		health = new_value
		if health < prev:
			if health <= 0:
				health_decreased_and_depleted.emit()
			else:
				health_decreased_but_not_depleted.emit()
		elif health > prev:
			health_increased.emit()
	get:
		return health


func _ready() -> void:
	if max_health <= 0:
		push_warning("Stats: max_health must be > 0")
		max_health = 1
	if health == 0:
		health = max_health


## 直接扣血（推荐用 hit_box 触发，这里提供手动调用接口）
func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health -= amount


## 治疗
func heal(amount: int) -> void:
	if amount <= 0:
		return
	health += amount


## 是否死亡
func is_dead() -> bool:
	return health <= 0


## 是否满血
func is_full_hp() -> bool:
	return health >= max_health


## 重置（用于重置关卡/重生）
func reset() -> void:
	health = max_health


## 当前生命百分比 (0.0-1.0)
func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)

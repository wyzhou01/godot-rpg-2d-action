class_name Knight extends BaseEnemy
## 近战骑士（直冲型）
##
## 行为:
##   - 检测到玩家 → 持续追踪
##   - 距离近时攻击
##   - 有 20% 概率格挡

@export var block_chance: float = 0.2

var is_blocking: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("knight")
	if enemy_stats:
		block_chance = enemy_stats.block_chance
	move_speed = 90.0


func _state_attack(delta: float) -> void:
	velocity.x = 0
	# 攻击频率比 Archer 慢
	attack_timer -= delta if "attack_timer" in self else 0
	# 格挡随机触发
	if randf() < block_chance * delta * 5:  # 大约 0.2*5 = 1 次/秒
		is_blocking = true
		play_anim("block")
	else:
		is_blocking = false
		play_anim("attack")


func _on_hurt() -> void:
	# Knight 受击时尝试格挡
	if is_blocking:
		play_anim("block")  # 不扣血（已经在 Stats 里扣了，这里只是视觉效果）
		return
	super._on_hurt()

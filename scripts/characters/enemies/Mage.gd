class_name Mage extends BaseEnemy
## 法师（远程魔法 + 召唤骷髅）
##
## 行为:
##   - 检测到玩家 → 停下
##   - 持续发射魔法弹（attack_cooldown）
##   - 每 8 秒召唤 1 只骷髅（can_summon=true）
##
## 节点结构: 同 Archer，但 projectile_spawner 改为 MagicSpawner

@export var projectile_scene: PackedScene
@export var summon_scene: PackedScene  # 骷髅场景
@export var attack_cooldown: float = 2.0
@export var summon_cooldown: float = 8.0

var attack_timer: float = 0.0
var summon_timer: float = 4.0  # 第一次召唤延迟


func _ready() -> void:
	super._ready()
	add_to_group("mage")
	if enemy_stats:
		attack_cooldown = enemy_stats.attack_cooldown
		summon_cooldown = enemy_stats.summon_cooldown


func _state_chase(delta: float) -> void:
	if not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= (enemy_stats.attack_range if enemy_stats else 400.0):
		# 攻击范围
		velocity.x = 0
		play_anim("idle")
		facing = int(sign(player.global_position.x - global_position.x))
		_update_sprite_direction()

		attack_timer -= delta
		if attack_timer <= 0:
			_cast_magic()
			attack_timer = attack_cooldown

		if enemy_stats and enemy_stats.can_summon:
			summon_timer -= delta
			if summon_timer <= 0:
				_summon_skeleton()
				summon_timer = summon_cooldown
	else:
		# 距离太远
		var direction = sign(player.global_position.x - global_position.x)
		facing = int(direction)
		velocity.x = direction * move_speed
		play_anim("run")


func _cast_magic() -> void:
	if projectile_scene == null:
		return

	var magic = projectile_scene.instantiate()
	get_parent().add_child(magic)
	magic.global_position = global_position

	var direction = Vector2.RIGHT if facing > 0 else Vector2.LEFT
	if is_instance_valid(player):
		direction = (player.global_position - magic.global_position).normalized()
		# 魔法可以斜飞（不像箭水平）

	if magic.has_method("initialize"):
		var speed = (enemy_stats.projectile_speed if enemy_stats else 350.0)
		magic.initialize(direction, speed)
		magic.attacker = self


func _summon_skeleton() -> void:
	if summon_scene == null:
		return

	var skel = summon_scene.instantiate()
	get_parent().add_child(skel)
	skel.global_position = global_position + Vector2(facing * 30, 0)
	play_anim("summon")

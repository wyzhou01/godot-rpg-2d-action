class_name Greyr1 extends BaseBoss
## Chapter 1 Boss「灰鸦」—— 堕落的斥候长
##
## 背景故事:
##   曾经是圣剑骑士团的斥候长，三年前的内斗中背叛骑士团，偷走了第一块碎片。
##   现在隐藏在荒原的废墟中，等待主角的到来。
##
## 战斗设计（3 阶段）:
##   Phase 1 (100%-66% HP): 基础攻击
##     - Slash Combo (近战 3 段)
##     - Shadow Step (瞬移)
##   Phase 2 (66%-33% HP): 增加远程
##     - 上述 + Poison Arrow (毒箭)
##     - 召唤 2 只 Knight
##   Phase 3 (33%-0% HP): 狂暴
##     - 移动速度 +50%, 攻击 +30%
##     - 大招 Blackout (全屏伤害)
##
## 节点结构:
##   Greyr1 (CharacterBody2D, 挂 Greyr1.gd)
##   ├── (BaseBoss 节点)
##   ├── BeehaveTree
##   ├── ProjectileSpawner (ArrowSpawn)
##   └── SummonSpawnPoint

@export var chapter_number: int = 1

# 阶段阈值（如果 boss_stats 没设置）
const DEFAULT_PHASE_2_HP := 0.66
const DEFAULT_PHASE_3_HP := 0.33

# 行为参数
@export var slash_damage: int = 15
@export var arrow_damage: int = 8
@export var summon_cooldown: float = 10.0
@export var rage_speed_multiplier: float = 1.5
@export var rage_attack_multiplier: float = 1.3

# 子节点
@onready var projectile_spawner: Node2D = $ProjectileSpawner

# 状态
var summon_timer: float = 8.0
var skill_cooldown: float = 0.0
var is_raged: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("chapter_boss")
	current_phase = 1


func _update_ai(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var hp_percent = stats.get_health_percent()
	var attack_range = 90.0
	var distance = global_position.distance_to(player.global_position)

	# 阶段切换处理
	if hp_percent <= DEFAULT_PHASE_3_HP and not is_raged:
		is_raged = true
		move_speed *= rage_speed_multiplier
		play_anim("rage")
		_dialogue("res://dialogs/greyr1_phase3.dlg")

	# 技能冷却
	if skill_cooldown > 0:
		skill_cooldown -= delta

	# 选择技能
	if distance <= attack_range:
		# 近战
		velocity.x = 0
		if skill_cooldown <= 0:
			_slash_combo()
			skill_cooldown = 2.0
		else:
			play_anim("idle")
	elif current_phase >= 2:
		# Phase 2+: 远程
		if skill_cooldown <= 0:
			_shoot_arrow()
			skill_cooldown = 1.5
		else:
			# 边退边打
			var direction = sign(player.global_position.x - global_position.x)
			facing = -int(direction)
			velocity.x = -direction * move_speed * 0.6
		play_anim("walk")
	else:
		# Phase 1: 追踪
		var direction = sign(player.global_position.x - global_position.x)
		facing = int(direction)
		velocity.x = direction * move_speed
		play_anim("walk")

	# 召唤（Phase 2+）
	if current_phase >= 2:
		summon_timer -= delta
		if summon_timer <= 0:
			_summon_knight()
			summon_timer = summon_cooldown


# ===== 技能实现 =====
func _slash_combo() -> void:
	play_anim("slash")
	# 启用 SwordHitbox，3 段攻击
	# AnimationPlayer 方法 track 控制 enable/disable
	pass


func _shoot_arrow() -> void:
	play_anim("shoot")
	# 生成箭
	var arrow_scene = preload("res://scenes/characters/projectiles/arrow.tscn")
	if arrow_scene == null:
		return
	var arrow = arrow_scene.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = projectile_spawner.global_position

	var direction = (player.global_position - arrow.global_position).normalized()
	direction.y = 0
	direction = direction.normalized()

	if arrow.has_method("initialize"):
		arrow.initialize(direction, 700.0)
		arrow.attacker = self
		arrow.damage = arrow_damage


func _summon_knight() -> void:
	play_anim("summon")
	var knight_scene = preload("res://scenes/characters/enemies/knight.tscn")
	if knight_scene == null:
		return
	# 在玩家身后召唤 2 只
	for i in 2:
		var k = knight_scene.instantiate()
		get_parent().add_child(k)
		k.global_position = player.global_position + Vector2((i*2-1) * 50, 0)


func _trigger_post_battle_dialogue() -> void:
	_dialogue("res://dialogs/greyr1_defeat.dlg")
	# 给予碎片
	if boss_stats and boss_stats.drops_shard:
		# 触发全局事件：玩家获得碎片
		var game_state = get_node("/root/GameState")
		if game_state and game_state.has_method("collect_shard"):
			game_state.collect_shard(boss_stats.shard_id)


func _dialogue(timeline: String) -> void:
	# 用 Dialogic 触发对话
	# Dialogic.start(timeline)
	dialogue_triggered.emit(timeline)

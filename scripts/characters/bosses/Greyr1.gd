class_name Greyr1 extends BaseBoss
## Chapter 1 Boss「灰鸦」—— 堕落的斥候长
##
## AI 阶段:
##   Phase 1 (满血): Chase + Slash Combo
##   Phase 2 (< 66% HP): Chase + Slash + Shoot Arrow (2s 间隔)
##   Phase 3 (< 33% HP, rage): Chase (1.5x) + Slash (1.3x dmg, 1s) + Summon Knight (8s)
##
## 战前/战后 Dialogic 替代方案（直接调 DialogueHelper）

@export var chapter_number: int = 1

# 阶段特定参数
var rage_speed_multiplier: float = 1.5
var rage_damage_multiplier: float = 1.3


func _ready() -> void:
	super._ready()
	add_to_group("chapter_boss")
	current_phase = 1


# ===== AI 行为 =====
func _ai_tick(_delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var attack_range = 80.0
	var current_speed = move_speed
	var current_damage = 15
	var attack_cooldown = 1.5

	# 阶段 3: 狂暴
	if current_phase >= 3:
		current_speed = move_speed * rage_speed_multiplier
		current_damage = int(15 * rage_damage_multiplier)
		attack_cooldown = 1.0

	# Chase 或 Attack
	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(current_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 阶段 2+: 射箭
	if current_phase >= 2 and _shoot_timer <= 0 and distance < 400:
		if shoot_at_player(8):
			_shoot_timer = 2.0

	# 阶段 3: 召唤 Knight
	if current_phase >= 3 and _summon_timer <= 0 and is_player_in_range(200):
		if summon_knight():
			_summon_timer = 8.0


# ===== 对话触发 =====
func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	# 第一次发现玩家触发战前对话
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_1_boss_intro.json")


func _trigger_post_battle_dialogue() -> void:
	# 战后对话
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_1_boss_defeat.json")
	# 收集碎片
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

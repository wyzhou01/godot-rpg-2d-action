class_name Frost extends BaseBoss
## Chapter 2 Boss「寒霜」—— 叛教法师
##
## AI 模式:
##   Phase 1: 冰弹 (3s 间隔) + 冰霜新星 (8s, 攻击范围 200)
##   Phase 2: + 冰甲 (受击时 10% 概率，反弹 30% 伤害)
##   Phase 3: 暴风雪 (15s, 全屏持续伤害) + 冰枪 (5s, 直线穿透)

var ice_bolt_cooldown: float = 0.0
var frost_nova_cooldown: float = 5.0
var blizzard_cooldown: float = 12.0
var ice_lance_cooldown: float = 3.0
var has_ice_armor: bool = false


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 18
	var attack_cooldown = 1.0
	var attack_range = 250.0

	# 阶段 3: 狂暴
	if current_phase >= 3:
		current_speed = move_speed * 1.4
		attack_damage = int(18 * 1.5)

	# Chase / Attack
	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 冰弹 (3s)
	ice_bolt_cooldown -= delta
	if ice_bolt_cooldown <= 0 and is_player_in_range(400):
		if _cast_ice_bolt(p):
			ice_bolt_cooldown = 3.0

	# 冰霜新星 (8s, AOE)
	frost_nova_cooldown -= delta
	if frost_nova_cooldown <= 0 and is_player_in_range(200):
		if _cast_frost_nova(attack_damage):
			frost_nova_cooldown = 8.0

	# 冰枪 (5s, Phase 3+)
	if current_phase >= 3:
		ice_lance_cooldown -= delta
		if ice_lance_cooldown <= 0 and is_player_in_range(350):
			if _cast_ice_lance(attack_damage * 2):
				ice_lance_cooldown = 5.0

	# 暴风雪 (15s, Phase 3+)
	if current_phase >= 3:
		blizzard_cooldown -= delta
		if blizzard_cooldown <= 0:
			if _cast_blizzard(int(attack_damage / 2)):
				blizzard_cooldown = 15.0

	# Phase 2: 冰甲
	if current_phase >= 2 and not has_ice_armor:
		has_ice_armor = true
		# 简单实现：受击反弹 30% 伤害
		# 在 _on_hurt 加上


func _cast_ice_bolt(target: Node2D) -> bool:
	var p = get_player()
	if not p:
		return false
	play_anim("cast")
	return shoot_at_player(8, 400.0)  # 冰弹伤害低但快


func _cast_frost_nova(damage: int) -> bool:
	play_anim("nova")
	# 范围 AOE 伤害
	var p = get_player()
	if p:
		var p_stats = p.get_node_or_null("Stats")
		if p_stats:
			p_stats.take_damage(damage)
	return true


func _cast_ice_lance(damage: int) -> bool:
	play_anim("lance")
	# 直线穿透
	return shoot_at_player(damage, 800.0)


func _cast_blizzard(damage: int) -> bool:
	play_anim("blizzard")
	# 持续伤害（简化：单次伤害）
	var p = get_player()
	if p:
		var p_stats = p.get_node_or_null("Stats")
		if p_stats:
			p_stats.take_damage(damage)
	return true


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_2_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_2_boss_intro.json")
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

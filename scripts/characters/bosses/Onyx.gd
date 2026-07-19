class_name Onyx extends BaseBoss
## Chapter 7 Final Boss「黑曜」—— 玩家曾经的导师/团长
##
## AI 模式 (最难的最终 boss):
##   Phase 1: 暗影斩 (近战) + 影步 (teleport 5s)
##   Phase 2: + 腐化治疗 (回 HP, 15s)
##   Phase 3: 湮灭一击 (致命, 25s) + 暗影斩 x3 + 腐化治疗

var shadow_step_cooldown: float = 3.0
var corrupted_heal_cooldown: float = 12.0
var oblivion_strike_cooldown: float = 20.0


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 35
	var attack_cooldown = 0.7
	var attack_range = 100.0

	if current_phase >= 3:
		current_speed = move_speed * 1.8
		attack_damage = int(35 * 2.0)

	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 影步 (5s, teleport)
	shadow_step_cooldown -= delta
	if shadow_step_cooldown <= 0 and is_player_in_range(200):
		play_anim("step")
		# teleport 到玩家身边
		global_position = p.global_position + Vector2(facing * -80, 0)
		shadow_step_cooldown = 5.0

	# 腐化治疗 (Phase 2+)
	if current_phase >= 2:
		corrupted_heal_cooldown -= delta
		if corrupted_heal_cooldown <= 0:
			play_anim("heal")
			# 回血
			if stats:
				stats.health = min(stats.max_health, stats.health + 50)
			corrupted_heal_cooldown = 15.0

	# 湮灭一击 (Phase 3, 致命)
	if current_phase >= 3:
		oblivion_strike_cooldown -= delta
		if oblivion_strike_cooldown <= 0:
			play_anim("oblivion")
			# 致命一击：直接 200 伤害（可一击秒杀）
			attack_player(200)
			oblivion_strike_cooldown = 25.0


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_7_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_7_boss_intro.json")
	# 收集最后一个碎片 + 通关
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)
		# 通关：所有 7 个碎片都收集了
		if gs and gs.has_method("complete_game"):
			gs.complete_game()

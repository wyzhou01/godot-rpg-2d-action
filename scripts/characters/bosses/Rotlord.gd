class_name Rotlord extends BaseBoss
## Chapter 3 Boss「腐骨」—— 死灵领主
##
## AI 模式:
##   Phase 1: 召唤骷髅 (12s) + 暗影箭 (2s)
##   Phase 2: + 死亡之握 (8s, 抓取 1s)
##   Phase 3: 灵魂吸取 (10s, 持续伤害) + 召唤 x2 + 死亡之握

var summon_timer_boss: float = 8.0
var shadow_bolt_cooldown: float = 0.0
var death_grip_cooldown: float = 5.0
var soul_drain_cooldown: float = 8.0


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 20
	var attack_cooldown = 1.2

	if current_phase >= 3:
		current_speed = move_speed * 1.5
		attack_damage = int(20 * 1.3)

	if distance > 100:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 召唤骷髅
	summon_timer_boss -= delta
	if summon_timer_boss <= 0:
		if _summon_skeleton():
			summon_timer_boss = 12.0 if current_phase < 3 else 8.0

	# 暗影箭
	shadow_bolt_cooldown -= delta
	if shadow_bolt_cooldown <= 0 and is_player_in_range(350):
		if shoot_at_player(8, 450.0):
			shadow_bolt_cooldown = 2.0

	# 死亡之握 (Phase 2+)
	if current_phase >= 2:
		death_grip_cooldown -= delta
		if death_grip_cooldown <= 0 and is_player_in_range(150):
			play_anim("grip")
			attack_player(15)
			death_grip_cooldown = 8.0

	# 灵魂吸取 (Phase 3)
	if current_phase >= 3:
		soul_drain_cooldown -= delta
		if soul_drain_cooldown <= 0 and is_player_in_range(100):
			play_anim("drain")
			# 持续 3 秒每秒 5 伤害
			for i in 3:
				attack_player(5)
			soul_drain_cooldown = 10.0


func _summon_skeleton() -> bool:
	play_anim("summon")
	return summon_knight()


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_3_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_3_boss_intro.json")
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

class_name Fireheart extends BaseBoss
## Chapter 5 Boss「炎心」—— 千年前第一位守护者
##
## AI 模式:
##   Phase 1: 喷火 (扇形范围 4s) + 火焰拳 (近战)
##   Phase 2: + 喷发 (8s, AOE 火焰柱)
##   Phase 3: 陨石 (15s, 范围超大) + 火焰风暴 + 火焰拳

var fire_breath_cooldown: float = 0.0
var eruption_cooldown: float = 5.0
var meteor_strike_cooldown: float = 12.0
var fire_storm_cooldown: float = 8.0


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 30
	var attack_cooldown = 0.8
	var attack_range = 100.0

	if current_phase >= 3:
		current_speed = move_speed * 1.6
		attack_damage = int(30 * 1.7)

	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 喷火 (4s, 扇形)
	fire_breath_cooldown -= delta
	if fire_breath_cooldown <= 0 and is_player_in_range(200):
		play_anim("breath")
		attack_player(15)  # 范围伤害
		fire_breath_cooldown = 4.0

	# 喷发 (Phase 2+)
	if current_phase >= 2:
		eruption_cooldown -= delta
		if eruption_cooldown <= 0 and is_player_in_range(300):
			play_anim("eruption")
			attack_player(40)
			eruption_cooldown = 8.0

	# 陨石 (Phase 3)
	if current_phase >= 3:
		meteor_strike_cooldown -= delta
		if meteor_strike_cooldown <= 0:
			play_anim("meteor")
			attack_player(60)  # 巨大伤害
			meteor_strike_cooldown = 15.0

	# 火焰风暴 (Phase 3+)
	if current_phase >= 3:
		fire_storm_cooldown -= delta
		if fire_storm_cooldown <= 0 and is_player_in_range(250):
			play_anim("storm")
			# 持续 3 秒每秒 8 伤害
			for i in 3:
				attack_player(8)
			fire_storm_cooldown = 8.0


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_5_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_5_boss_intro.json")
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

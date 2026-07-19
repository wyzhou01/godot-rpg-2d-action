class_name Greendruid extends BaseBoss
## Chapter 6 Boss「翠语」—— 暗影德鲁伊
##
## AI 模式:
##   Phase 1: 藤鞭 (近战, 1.5s) + 毒孢 (5s, 范围 DOT)
##   Phase 2: + 缠绕 (10s, 定身 2s)
##   Phase 3: 森林之怒 (15s) + 藤鞭 x2 + 毒风暴

var vine_whip_cooldown: float = 0.0
var poison_spore_cooldown: float = 3.0
var entangle_cooldown: float = 7.0
var forest_wrath_cooldown: float = 12.0
var poison_storm_cooldown: float = 8.0


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 28
	var attack_cooldown = 1.0
	var attack_range = 100.0

	if current_phase >= 3:
		current_speed = move_speed * 1.5
		attack_damage = int(28 * 1.5)

	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 藤鞭 (1.5s)
	vine_whip_cooldown -= delta
	if vine_whip_cooldown <= 0 and is_player_in_range(150):
		play_anim("whip")
		attack_player(15)
		vine_whip_cooldown = 1.5

	# 毒孢 (5s, 范围 DOT)
	poison_spore_cooldown -= delta
	if poison_spore_cooldown <= 0 and is_player_in_range(200):
		play_anim("spore")
		attack_player(10)  # DOT 启动
		poison_spore_cooldown = 5.0

	# 缠绕 (Phase 2+)
	if current_phase >= 2:
		entangle_cooldown -= delta
		if entangle_cooldown <= 0 and is_player_in_range(120):
			play_anim("entangle")
			attack_player(20)  # 定身 + 伤害
			entangle_cooldown = 10.0

	# 森林之怒 (Phase 3)
	if current_phase >= 3:
		forest_wrath_cooldown -= delta
		if forest_wrath_cooldown <= 0:
			play_anim("wrath")
			# AOE 大伤害
			attack_player(50)
			forest_wrath_cooldown = 15.0

	# 毒风暴 (Phase 3)
	if current_phase >= 3:
		poison_storm_cooldown -= delta
		if poison_storm_cooldown <= 0 and is_player_in_range(250):
			play_anim("storm")
			for i in 3:
				attack_player(12)
			poison_storm_cooldown = 8.0


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_6_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_6_boss_intro.json")
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

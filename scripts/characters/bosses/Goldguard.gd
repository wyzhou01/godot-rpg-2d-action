class_name Goldguard extends BaseBoss
## Chapter 4 Boss「金卫」—— 圣殿骑士长（玩家的导师）
##
## AI 模式:
##   Phase 1: 剑连击 (近战, 1.2s) + 盾击 (3s, 击退)
##   Phase 2: + 圣击 (8s, 范围伤害)
##   Phase 3: 神圣审判 (15s, 连续攻击) + 剑连击 x2 + 盾击

var shield_bash_cooldown: float = 2.0
var holy_smite_cooldown: float = 6.0
var divine_judgment_cooldown: float = 12.0


func _ai_tick(delta: float) -> void:
	var p = get_player()
	if not is_instance_valid(p):
		state = BossState.IDLE
		return

	var distance = global_position.distance_to(p.global_position)
	var current_speed = move_speed
	var attack_damage = 25
	var attack_cooldown = 1.2
	var attack_range = 90.0

	if current_phase >= 3:
		current_speed = move_speed * 1.4
		attack_damage = int(25 * 1.6)

	if distance > attack_range:
		state = BossState.CHASE
		move_toward_player(current_speed)
	elif _attack_timer <= 0:
		state = BossState.ATTACK
		attack_player(attack_damage)
		_attack_timer = attack_cooldown
	else:
		state = BossState.IDLE

	# 盾击 (3s)
	shield_bash_cooldown -= delta
	if shield_bash_cooldown <= 0 and is_player_in_range(120):
		play_anim("bash")
		attack_player(15)
		# 击退（简化：伤害已加，不再处理位移）
		shield_bash_cooldown = 3.0

	# 圣击 (Phase 2+)
	if current_phase >= 2:
		holy_smite_cooldown -= delta
		if holy_smite_cooldown <= 0 and is_player_in_range(200):
			play_anim("smite")
			attack_player(30)  # 范围伤害
			holy_smite_cooldown = 8.0

	# 神圣审判 (Phase 3)
	if current_phase >= 3:
		divine_judgment_cooldown -= delta
		if divine_judgment_cooldown <= 0:
			play_anim("judgment")
			# 连续 5 次攻击
			for i in 5:
				attack_player(10)
			divine_judgment_cooldown = 15.0


func _on_player_detected(p: Node2D) -> void:
	super._on_player_detected(p)
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_4_boss_intro.json_defeat.json")


func _trigger_post_battle_dialogue() -> void:
	var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
	if dh and dh.has_method("show"):
		dh.show.call_deferred("res://dialogs/chapter_4_boss_intro.json")
	if boss_stats and boss_stats.drops_shard:
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and gs.has_method("collect_shard"):
			gs.collect_shard(boss_stats.shard_id)

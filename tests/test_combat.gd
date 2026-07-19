extends Node
## 战斗系统测试 - 用 await 链避免 race

const TestFramework = preload("res://tests/test_framework.gd")

var _tf: TestFramework
var _current_scene: Node = null
var _player: Node = null


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	# 等一帧再跑，避免 root 忙
	call_deferred("_start_tests")


func _start_tests() -> void:
	_run_all()


func _run_all() -> void:
	_tf.start_suite("combat")
	
	# 顺序 await
	await _test_player_spawn()
	await _test_player_stats()
	await _test_player_sword()
	await _test_player_sprite()
	await _test_player_initial_hp()
	await _test_player_idle_state()
	await _test_player_moves()
	await _test_player_flip()
	await _test_player_damage()
	await _test_player_hp_decrease()
	await _test_enemy_spawn()
	await _test_enemy_stats()
	await _test_boss_death_listener()
	
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _load_chapter(idx: int, stage: String = "intro") -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		await get_tree().process_frame
		_current_scene = null
	_player = null
	var path = "res://scenes/levels/chapter_%d/chapter_%d_%s.tscn" % [idx, idx, stage]
	var scene = load(path)
	_current_scene = scene.instantiate()
	get_tree().root.add_child.call_deferred(_current_scene)
	# 等多帧让 root 接受 deferred add
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if _current_scene and is_instance_valid(_current_scene) and _current_scene.get_parent() != null:
		get_tree().current_scene = _current_scene
	await get_tree().create_timer(2.0).timeout
	_player = _current_scene.get_tree().get_first_node_in_group("player")


func _test_player_spawn() -> void:
	await _load_chapter(1, "intro")
	var pass2 = _player != null and (_player is CharacterBody2D)
	_tf.run_test("player spawns", func(): return {"pass": pass2, "message": "Player is null or not CharacterBody2D"})


func _test_player_stats() -> void:
	var stats = _player.get_node_or_null("Stats") if _player else null
	if stats == null:
		await _load_chapter(1, "intro")
		stats = _player.get_node_or_null("Stats") if _player else null
	var pass2 = stats != null and "health" in stats
	_tf.run_test("player has Stats with health", func(): return {"pass": pass2, "message": "no Stats or no health"})


func _test_player_sword() -> void:
	var sword = _player.find_child("SwordHitbox", true, false) if _player else null
	_tf.run_test("player has SwordHitbox", func(): return {"pass": sword != null, "message": "no SwordHitbox"})


func _test_player_sprite() -> void:
	var sprite = _player.get_node_or_null("AnimatedSprite2D") if _player else null
	var pass2 = sprite != null and sprite.sprite_frames != null
	_tf.run_test("player has AnimatedSprite2D with sprite_frames", func(): return {"pass": pass2, "message": "no sprite"})


func _test_player_initial_hp() -> void:
	var stats = _player.get_node_or_null("Stats") if _player else null
	if stats == null:
		_tf.run_test("player initial HP", func(): return {"pass": false, "message": "no stats"})
		return
	var pass2 = stats.max_health > 0 and stats.health == stats.max_health
	_tf.run_test("player initial HP = max HP", func(): return {"pass": pass2, "message": "HP %d max %d" % [stats.health, stats.max_health]})


func _test_player_idle_state() -> void:
	if _player == null:
		await _load_chapter(1, "intro")
	if _player == null:
		_tf.run_test("player state starts IDLE", func(): return {"pass": false, "message": "No player"})
		return
	var pass2 = _player.state == _player.PlayerState.IDLE
	_tf.run_test("player state starts IDLE", func(): return {"pass": pass2, "message": "state is %d" % _player.state})


func _test_player_moves() -> void:
	if _player == null:
		await _load_chapter(1, "intro")
	var initial_pos = _player.global_position
	Input.action_press("move_right")
	await get_tree().create_timer(0.5).timeout
	Input.action_release("move_right")
	await get_tree().create_timer(0.1).timeout
	var pass2 = _player.global_position.x > initial_pos.x
	_tf.run_test("player moves right on input", func(): return {"pass": pass2, "message": "pos %s -> %s" % [initial_pos, _player.global_position]})


func _test_player_flip() -> void:
	if _player == null:
		await _load_chapter(1, "intro")
	Input.action_press("move_left")
	await get_tree().create_timer(0.5).timeout
	Input.action_release("move_left")
	await get_tree().create_timer(0.1).timeout
	var sprite = _player.get_node_or_null("AnimatedSprite2D")
	var pass2 = sprite != null and sprite.scale.x < 0
	_tf.run_test("player flips sprite left", func(): return {"pass": pass2, "message": "scale.x=%f" % (sprite.scale.x if sprite else 0)})


func _test_player_damage() -> void:
	if _player == null:
		await _load_chapter(1, "intro")
	var stats = _player.get_node_or_null("Stats")
	if stats == null:
		_tf.run_test("player takes damage", func(): return {"pass": false, "message": "no stats"})
		return
	var received = [false]
	stats.health_decreased_but_not_depleted.connect(func(): received[0] = true)
	stats.health = stats.max_health - 10
	await get_tree().create_timer(0.1).timeout
	_tf.run_test("damage signal fires", func(): return {"pass": received[0], "message": "no signal"})


func _test_player_hp_decrease() -> void:
	if _player == null:
		await _load_chapter(1, "intro")
	var stats = _player.get_node_or_null("Stats")
	if stats == null:
		_tf.run_test("HP decreases", func(): return {"pass": false, "message": "no stats"})
		return
	var initial = stats.health
	stats.health = initial - 25
	await get_tree().create_timer(0.1).timeout
	var pass2 = stats.health == initial - 25
	_tf.run_test("HP decreases by damage", func(): return {"pass": pass2, "message": "%d != %d" % [stats.health, initial - 25]})


func _test_enemy_spawn() -> void:
	if _current_scene == null or _current_scene.scene_file_path.find("chapter_1_intro") == -1:
		await _load_chapter(1, "intro")
	# 重置 HP
	if _player:
		var s = _player.get_node_or_null("Stats")
		if s:
			s.health = s.max_health
	await get_tree().create_timer(2.0).timeout
	# 递归找所有 CharacterBody2D
	var found = false
	_find_enemy_recursive(_current_scene, found)
	for child in _current_scene.find_children("*", "CharacterBody2D", true, false):
		if child != _player:
			found = true
			break
	_tf.run_test("enemy spawned in chapter 1", func(): return {"pass": found, "message": "no enemies"})


func _find_enemy_recursive(node: Node, _dummy: bool) -> void:
	pass  # placeholder


func _test_enemy_stats() -> void:
	if _current_scene == null:
		await _load_chapter(1, "intro")
	await get_tree().create_timer(2.0).timeout
	for child in _current_scene.find_children("*", "CharacterBody2D", true, false):
		if child != _player:
			var stats = child.get_node_or_null("Stats")
			_tf.run_test("enemy has Stats", func(): return {"pass": stats != null, "message": "no stats"})
			return
	_tf.run_test("enemy has Stats", func(): return {"pass": false, "message": "no enemy"})


func _test_boss_death_listener() -> void:
	await _load_chapter(1, "boss")
	await get_tree().create_timer(1.0).timeout
	var boss_names = ["Greyr1", "Frost", "Rotlord", "Goldguard", "Fireheart", "Greendruid", "Onyx", "Boss"]
	var boss = null
	for n in boss_names:
		boss = _current_scene.find_child(n, true, false)
		if boss:
			break
	if boss == null:
		_tf.run_test("Boss death listener", func(): return {"pass": false, "message": "no Boss"})
		return
	var boss_stats = boss.get_node_or_null("Stats")
	if boss_stats == null:
		_tf.run_test("Boss death listener", func(): return {"pass": false, "message": "Boss no Stats"})
		return
	var conns = boss_stats.health_decreased_and_depleted.get_connections()
	_tf.run_test("Boss death listener registered", func(): return {"pass": conns.size() > 0, "message": "%d connections" % conns.size()})




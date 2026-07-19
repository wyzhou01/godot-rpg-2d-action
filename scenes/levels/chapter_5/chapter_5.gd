extends Node2D
## Chapter 5 关卡控制

@export var next_scene: String = "res://scenes/levels/chapter_5/chapter_5_combat.tscn"
@export var chapter_name: String = "Chapter 5"
@export var show_intro_dialog: bool = true
@export var intro_dialog_path: String = "res://dialogs/chapter_5_intro.json"

var player: Node = null

# 敌人场景
const ARCHER_SCENE := "res://scenes/characters/enemies/archer.tscn"
const MAGE_SCENE := "res://scenes/characters/enemies/mage.tscn"
const KNIGHT_SCENE := "res://scenes/characters/enemies/knight.tscn"


func _ready() -> void:
	# 显示章节 intro 对话
	if show_intro_dialog and intro_dialog_path and DialogueHelper:
		DialogueHelper.dialogue_ended.connect(_on_intro_dialog_ended, CONNECT_ONE_SHOT)
		DialogueHelper.show(intro_dialog_path)
		await DialogueHelper.dialogue_ended
	# 找 Player
	player = get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.health_decreased_and_depleted.connect(_on_player_died)

	# 找 ExitTrigger
	var exit_trigger = find_child("ExitTrigger", true, false)
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_entered)

	# 生成敌人
	_spawn_enemies()
	
	# 监听 Boss 死亡（如果是 boss 场景）
	var boss_node = find_child("Boss", true, false)
	if boss_node == null:
		boss_node = find_child("Greyr1", true, false)
	if boss_node == null:
		boss_node = find_child("Frost", true, false)
	if boss_node == null:
		boss_node = find_child("Rotlord", true, false)
	if boss_node == null:
		boss_node = find_child("Goldguard", true, false)
	if boss_node == null:
		boss_node = find_child("Fireheart", true, false)
	if boss_node == null:
		boss_node = find_child("Greendruid", true, false)
	if boss_node == null:
		boss_node = find_child("Onyx", true, false)
	if boss_node:
		var boss_stats = boss_node.get_node_or_null("Stats")
		if boss_stats:
			boss_stats.health_decreased_and_depleted.connect(_on_boss_defeated)


func _spawn_enemies() -> void:
	var spawn_points = find_child("SpawnPoints", true, false)
	if not spawn_points:
		return
	var enemies_root = find_child("Enemies", true, false)
	if not enemies_root:
		return

	var archer_scene = load(ARCHER_SCENE)
	var mage_scene = load(MAGE_SCENE)
	var knight_scene = load(KNIGHT_SCENE)

	for child in spawn_points.get_children():
		if not child is Marker2D:
			continue
		# 第一个 spawn point 用 archer, 第二个 mage, 第三个 knight
		var scene = null
		match child.name:
			"SpawnPoint1":
				scene = archer_scene
			"SpawnPoint2":
				scene = mage_scene
			"SpawnPoint3":
				scene = knight_scene
		if scene:
			var enemy = scene.instantiate()
			enemies_root.add_child(enemy)
			enemy.global_position = child.global_position


func _on_player_died() -> void:
	# 等 1 秒后重置
	await get_tree().create_timer(1.0).timeout
	if player and is_instance_valid(player):
		player.global_position = get_node("SpawnPoint").global_position
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.reset()


func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# 切换到下一关
		if SceneManager and SceneManager.has_method("transition_to_scene"):
			SceneManager.transition_to_scene(next_scene)
		else:
			get_tree().change_scene_to_file(next_scene)


func _on_intro_dialog_ended(_timeline: String) -> void:
	# intro 对话结束，玩家可以移动
	pass


func _on_boss_defeated() -> void:
	# Boss 死亡 → 2s 后进下一章
	print("[", chapter_name, "] Boss defeated, going to next level in 2s")
	await get_tree().create_timer(2.0).timeout
	if SceneManager and SceneManager.has_method("transition_to_scene"):
		SceneManager.transition_to_scene(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)

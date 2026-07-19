extends Node2D
## Chapter 6 关卡控制（可玩版）
##
## 职责:
##   - 玩家死亡 → respawn（HP=0）
##   - Boss 死亡 → 显示 Fragment + portal
##   - 玩家进 Portal → 跳到 boss 战

@export var next_scene: String = ""
@export var chapter_name: String = "Chapter 6"
@export var show_intro_dialog: bool = true
@export var intro_dialog_path: String = "res://dialogs/chapter_1_intro.json"

var player: Node = null
var boss_killed: bool = false


func _ready() -> void:
	# 1. 找 Player
	player = get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.health_decreased_and_depleted.connect(_on_player_died)

	# 2. 找 Boss
	_boss = find_child("Greendruid", true, false)
	if _boss:
		var boss_stats = _boss.get_node_or_null("Stats")
		if boss_stats:
			boss_stats.health_decreased_and_depleted.connect(_on_boss_defeated)
		# Boss 没死时 portal 不可用
		_disable_portal()

	# 3. 显示章节 intro 对话
	if show_intro_dialog and intro_dialog_path and DialogueHelper:
		DialogueHelper.dialogue_ended.connect(_on_intro_dialog_ended, CONNECT_ONE_SHOT)
		DialogueHelper.show(intro_dialog_path)
		await DialogueHelper.dialogue_ended

var _boss: Node = null


func _on_intro_dialog_ended(_timeline: String) -> void:
	pass


func _on_player_died() -> void:
	# 1.5s 后 respawn
	await get_tree().create_timer(1.5).timeout
	if player and is_instance_valid(player):
		var spawn = get_node_or_null("PlayerSpawn")
		if spawn:
			player.global_position = spawn.global_position
		else:
			player.global_position = Vector2(100, 500)
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.reset()
		PlayerData.on_player_died()


func _on_boss_defeated() -> void:
	# Boss 死亡 → 显示 Fragment + 启用 Portal
	boss_killed = true
	print("[", chapter_name, "] Boss defeated!")
	_enable_portal()
	# 弹对话
	if DialogueHelper:
		DialogueHelper.show("res://dialogs/chapter_1_boss_defeat.json")


func _disable_portal() -> void:
	var portal = find_child("Portal", true, false)
	if portal:
		portal.set_deferred("monitoring", false)
		# 让 portal 不可见
		var sprite = portal.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)


func _enable_portal() -> void:
	var portal = find_child("Portal", true, false)
	if portal:
		portal.set_deferred("monitoring", true)
		var sprite = portal.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)


func get_player() -> Node:
	return player
extends Area2D
## 检查点（玩家走过 → 自动保存游戏）
##
## 玩家进入 → save_game(0, data) → 当前 chapter + position + HP + fragments

@onready var sprite: ColorRect = get_node_or_null("Sprite2D")

var activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not activated:
		activated = true
		_save_progress()
		# 视觉反馈：闪光
		_flash()


func _save_progress() -> void:
	var data = {
		"current_chapter": PlayerData.current_chapter,
		"current_hp": PlayerData.current_hp,
		"current_fp": PlayerData.current_fp,
		"fragments_collected": PlayerData.fragments_collected.duplicate(),
		"deaths": PlayerData.deaths,
		"score": PlayerData.score,
		"playtime_seconds": PlayerData.playtime_seconds,
		"position": {"x": global_position.x, "y": global_position.y},
		"scene_path": get_tree().current_scene.scene_file_path,
	}
	# 修复: 只存 slot 3 (自动存档)，不覆盖 slot 0-2 (玩家手动存档)
	SaveSystem.save_game(3, data)
	print("[Checkpoint] autosaved to slot 3 at ", global_position)


func _flash() -> void:
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 2, 0.5, 1), 0.3)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)

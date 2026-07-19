extends Area2D
class_name Portal2D
## 关卡传送门
##
## 玩家进入 → fade_out 动画 → 切到 next_scene

@export var next_scene: PackedScene
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

signal player_entered


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and next_scene:
		player_entered.emit()
		# 简单切场景（不强制 fade，等 Phase 4 加完整动画）
		get_tree().change_scene_to_packed(next_scene)
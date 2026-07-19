extends Area2D
class_name Fragment
## 圣物碎片（拾取后加入 PlayerData）
##
## 玩家走过 → 收集 → 弹对话 → 1.5s 后消失

@export var fragment_id: String = "ch1"
@export var color: Color = Color(1, 0.85, 0.3, 1)
@onready var sprite: ColorRect = $Sprite2D
@onready var label: Label = $Label


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if sprite:
		sprite.color = color


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		PlayerData.add_fragment(fragment_id)
		print("[Fragment] collected: ", fragment_id)
		# 简单效果：消失
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
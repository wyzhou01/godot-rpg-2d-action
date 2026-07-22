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
		if PlayerData.has_fragment(fragment_id):
			return  # 已收集不重复
		PlayerData.add_fragment(fragment_id)
		# 通知 GameState（解锁技能）
		var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
		if gs and fragment_id.begins_with("ch"):
			var id_num := fragment_id.substr(2).to_int()
			if id_num > 0:
				gs.collect_shard(id_num)
		print("[Fragment] collected: ", fragment_id)
		# 简单效果：消失
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
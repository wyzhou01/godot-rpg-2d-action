class_name DamageNumber extends Label
## 伤害飘字（受击时弹出）

@export var lifetime: float = 0.8
@export var float_distance: float = 30.0


func show_damage(amount: int, color: Color = Color.RED) -> void:
	text = str(amount)
	modulate = color
	# 上浮 + 淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_distance, lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


# 静态方法方便调用
static func spawn(parent: Node, position: Vector2, amount: int, color: Color = Color.RED) -> void:
	var dmg = DamageNumber.new()
	dmg.text = str(amount)
	dmg.position = position
	dmg.modulate = color
	parent.add_child(dmg)
	dmg.show_damage(amount, color)

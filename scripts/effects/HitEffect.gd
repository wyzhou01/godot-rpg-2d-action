class_name HitEffect extends OneShotEffect
## 受击特效（短闪烁 + 小粒子）

@export var color: Color = Color(1, 1, 1)


func _ready() -> void:
	lifetime = 0.3
	auto_play = true
	# 简单的 modulate 闪烁
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/effects/hit_flash.png") if ResourceLoader.exists("res://assets/effects/hit_flash.png") else null
	if sprite.texture == null:
		# 创建占位：红色圆
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(color)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
	add_child(sprite)
	super._ready()

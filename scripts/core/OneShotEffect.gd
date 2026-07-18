class_name OneShotEffect extends Node2D
## 一次性特效（粒子/动画）
## 用法: 实例化后添加到场景，动画结束自动销毁
##
## 子类: 实现具体特效动画（HitEffect / DeathEffect / ExplosionEffect）

@export var lifetime: float = 0.5  # 默认寿命（秒）
@export var auto_play: bool = true

@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null


func _ready() -> void:
	if auto_play:
		play()


func play() -> void:
	if animation_player:
		animation_player.play("default")
	if animated_sprite:
		animated_sprite.play("default")
	# 寿命到期销毁
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


## 子类可重写：在动画结束时调用
func on_finished() -> void:
	queue_free()

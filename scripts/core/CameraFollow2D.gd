extends Camera2D
## 简易相机跟随 Player

@export var smooth_speed: float = 5.0
@export var offset_y: float = -50.0  # 摄像机稍微往上一点，玩家更显眼

var _target: Node2D = null


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null:
		return
	var target_pos: Vector2 = _target.global_position + Vector2(0, offset_y)
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
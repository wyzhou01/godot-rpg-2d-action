class_name PlayerDetectionZone extends Area2D
## 玩家检测区域（敌人自动发现玩家）
## 用法: 挂在敌人下，命名为 PlayerDetectionZone
##
## 关键设计: 信号机制替代每帧 get_tree().get_first_node_in_group("player")
##   - 自动订阅 body_entered / body_exited
##   - 维护 player 引用 + player_detected 信号

signal player_detected(player: Node2D)
signal player_lost(player: Node2D)

const PLAYER_GROUP := "player"

var player: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	if player != null:
		return  # 已经检测到玩家
	player = body as Node2D
	player_detected.emit(player)


func _on_body_exited(body: Node) -> void:
	if body == player:
		player_lost.emit(player)
		player = null


## 敌人查询接口
func has_player() -> bool:
	return player != null and is_instance_valid(player)


## 强制清除（敌人死亡时）
func clear_player() -> void:
	if player:
		player_lost.emit(player)
	player = null

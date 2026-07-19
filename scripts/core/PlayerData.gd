extends Node
## 全局玩家数据
##
## 包含：章节、HP、FP、分数、死亡、碎片、游戏时间
## 信号：updated（数据变化）, died（死亡）, reset（新游戏）

signal updated
signal died
signal reset

var current_chapter: int = 1
var current_hp: int = 100
var max_hp: int = 100
var current_fp: int = 50
var max_fp: int = 50
var score: int = 0
var deaths: int = 0
var fragments_collected: Array = []  # ["ch1", "ch2", ...]
var playtime_seconds: float = 0.0
var last_save_position: Vector2 = Vector2(100, 300)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	playtime_seconds += delta


## 添加碎片（去重）
func add_fragment(fragment_id: String) -> void:
	if fragment_id not in fragments_collected:
		fragments_collected.append(fragment_id)
		emit_signal("updated")


## 是否收集了某碎片
func has_fragment(fragment_id: String) -> bool:
	return fragment_id in fragments_collected


## 7 碎片总数
func get_fragment_count() -> int:
	return fragments_collected.size()


## 玩家受伤
func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	emit_signal("updated")
	if current_hp <= 0:
		emit_signal("died")


## 玩家治疗
func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("updated")


## 新游戏
func reset_for_new_game() -> void:
	current_chapter = 1
	current_hp = max_hp
	current_fp = max_fp
	score = 0
	deaths = 0
	fragments_collected = []
	playtime_seconds = 0.0
	last_save_position = Vector2(100, 300)
	emit_signal("reset")


## 死亡（仅计数）
func on_player_died() -> void:
	deaths += 1
	emit_signal("died")


## 当前章节（getter）
func get_chapter() -> int:
	return current_chapter


## 设置章节
func set_chapter(ch: int) -> void:
	current_chapter = ch
	emit_signal("updated")
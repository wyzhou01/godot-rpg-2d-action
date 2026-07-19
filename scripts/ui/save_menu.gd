class_name SaveMenu extends Control
## 存档菜单 UI（4 存档位 + Save/Load/Delete）

const SaveSystemScript = preload("res://scripts/systems/save_system.gd")
# SceneManager 已是 autoload，直接用全局名 SceneManager

const SLOT_LABELS := ["手动 1", "手动 2", "手动 3", "自动存档"]
const SLOT_KEYS := ["0", "1", "2", "3"]

@onready var slot_buttons: Array = [
    $Margin/VBox/Slot1Button,
    $Margin/VBox/Slot2Button,
    $Margin/VBox/Slot3Button,
    $Margin/VBox/AutoSlotButton,
]
@onready var back_button: Button = $Margin/VBox/BackButton
@onready var info_label: Label = $InfoLabel


func _ready() -> void:
	_refresh_all_slots()
	back_button.pressed.connect(_on_back_pressed)
	for i in slot_buttons.size():
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i))


func _refresh_all_slots() -> void:
	for i in slot_buttons.size():
		var btn = slot_buttons[i]
		var slot_name = SLOT_LABELS[i]
		if SaveSystemScript.has_save(i):
			var data = SaveSystemScript.load_save(i)
			var chapter = data.get("current_chapter", 1)
			var play_time = data.get("total_play_time", 0.0)
			var time_str = _format_time(play_time)
			btn.text = "%s\n第 %d 章 | %s" % [slot_name, chapter, time_str]
		else:
			btn.text = "%s\n[空存档]" % slot_name
	_refresh_info_label("选择一个存档读档，或新建游戏覆盖")


func _on_slot_pressed(slot: int) -> void:
	if SaveSystemScript.has_save(slot):
		# 读档
		_load_slot(slot)
	else:
		# 新建
		_new_slot(slot)


func _load_slot(slot: int) -> void:
	# 加载 GameState 数据
	var data = SaveSystemScript.load_save(slot)
	if data.is_empty():
		return

	# 应用到 GameState
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs:
		gs.current_chapter = data.get("current_chapter", 1)
		gs.max_hp = data.get("max_hp", 100)
		gs.current_hp = data.get("current_hp", 100)
		gs.max_fp = data.get("max_fp", 50)
		gs.current_fp = data.get("current_fp", 50)
		gs.collected_shards = data.get("collected_shards", [])
		gs.defeated_bosses = data.get("defeated_bosses", [])
		gs.unlocked_abilities = data.get("unlocked_abilities", [])

	# 跳转到对应关卡
	var level_path = data.get("current_level_path", "")
	if level_path.is_empty():
		level_path = "res://scenes/levels/chapter_1/chapter_1_intro.tscn"
	if SceneManager and SceneManager.has_method("transition_to_scene"):
		SceneManager.transition_to_scene(level_path)
	else:
		get_tree().change_scene_to_file(level_path)


func _new_slot(slot: int) -> void:
	# 在该槽位新建（覆盖空存档）
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs:
		gs.current_chapter = 1
		gs.max_hp = 100
		gs.current_hp = 100
		gs.max_fp = 50
		gs.current_fp = 50
		gs.collected_shards = []
		gs.defeated_bosses = []
		gs.unlocked_abilities = []
	if SaveSystemScript.save_to_slot(slot):
		_refresh_all_slots()
		_refresh_info_label("✓ 新存档创建成功")


func _on_back_pressed() -> void:
	# 返回主菜单
	if SceneManager and SceneManager.has_method("goto_main_menu"):
		SceneManager.goto_main_menu()
	else:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _refresh_info_label(text: String) -> void:
	if info_label:
		info_label.text = text


func _format_time(seconds: float) -> String:
	var s = int(seconds)
	var h = s / 3600
	var m = (s % 3600) / 60
	var sec = s % 60
	if h > 0:
		return "%d小时%d分" % [h, m]
	elif m > 0:
		return "%d分%d秒" % [m, sec]
	return "%d秒" % sec

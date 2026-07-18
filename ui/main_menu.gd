extends Control
## EternalDuty 主菜单
##
## 按 New Game → 进入 Chapter 1
## 按 Continue → 加载最近存档
## 按 Options → 跳转到选项（暂未实现）
## 按 Quit → 退出游戏

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# 检查是否有存档，决定 Continue 按钮是否启用
	var has_save = false
	for slot in 4:
		if SaveSystem.has_save(slot):
			has_save = true
			break
	continue_button.visible = has_save

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	# 重置游戏状态
	GameState.current_chapter = 1
	GameState.current_hp = GameState.max_hp
	GameState.current_fp = GameState.max_fp
	GameState.collected_shards = []
	GameState.defeated_bosses = []
	GameState.unlocked_abilities = []
	GameState.dialogue_history = {}

	# 跳转到 Chapter 1
	if SaveSystem and SaveSystem.has_method("save_current_game"):
		SaveSystem.save_current_game()
	SceneManager.transition_to_scene("res://scenes/levels/chapter_1/chapter_1_intro.tscn")


func _on_continue_pressed() -> void:
	# 加载最近的有效存档（slot 0 优先，然后 1, 2, 3）
	var save_data = {}
	var slot_to_load = -1
	for slot in [0, 1, 2, 3]:
		if SaveSystem.has_save(slot):
			save_data = SaveSystem.load_save(slot)
			slot_to_load = slot
			break
	if slot_to_load < 0:
		return

	# 恢复到 GameState
	if save_data.has("current_chapter"):
		GameState.current_chapter = save_data.current_chapter
	# ... 其他字段恢复

	# 跳转到对应关卡
	var level_path = save_data.get("current_level_path", "res://scenes/levels/chapter_1/chapter_1_intro.tscn")
	if level_path.is_empty():
		level_path = "res://scenes/levels/chapter_1/chapter_1_intro.tscn"
	SceneManager.transition_to_scene(level_path)


func _on_options_pressed() -> void:
	# TODO: 实现选项菜单（基于 Maaack）
	push_warning("Options menu not yet implemented")


func _on_quit_pressed() -> void:
	get_tree().quit()

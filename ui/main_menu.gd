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
	# 信号已在 .tscn 里连接，不要重复 connect()


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
	# 显示存档/读档菜单让用户选 slot
	var save_menu = get_node_or_null("SaveLoadMenu")
	if save_menu and save_menu.has_method("show_menu"):
		save_menu.show_menu()
	else:
		# 退化：自动加载 slot 0
		if SaveSystem.has_save(0):
			var data = SaveSystem.load_save(0)
			_apply_save_and_continue(data, "res://scenes/levels/chapter_1/chapter_1_intro.tscn")


func _apply_save_and_continue(data: Dictionary, default_path: String) -> void:
	if data.is_empty():
		return
	if data.has("current_chapter"):
		GameState.current_chapter = data.current_chapter
	var level_path = data.get("current_level_path", default_path)
	if level_path.is_empty():
		level_path = default_path
	SceneManager.transition_to_scene(level_path)


func _on_options_pressed() -> void:
	pass

func _on_save_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/save_menu.tscn")
	# TODO: 实现选项菜单（基于 Maaack）
	push_warning("Options menu not yet implemented")


func _on_quit_pressed() -> void:
	get_tree().quit()

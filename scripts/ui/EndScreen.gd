extends CanvasLayer
## 结束画面（通关后显示）
##
## 玩家通关 Chapter 7 → game_complete 触发

@onready var title_label: Label = $Title
@onready var stats_label: Label = $Stats
@onready var menu_button: Button = $MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	_show_stats()


func show_end_screen() -> void:
	visible = true
	get_tree().paused = true


func hide_end_screen() -> void:
	visible = false
	get_tree().paused = false


func _show_stats() -> void:
	var minutes = int(PlayerData.playtime_seconds / 60)
	var seconds = int(PlayerData.playtime_seconds) % 60
	var time_str = "%d:%02d" % [minutes, seconds]
	if stats_label:
		stats_label.text = """
通 关 ！

通关时间:  %s
死亡次数:  %d
收集碎片:  %d / 7
当前分数:  %d

Thank you for playing!
""" % [time_str, PlayerData.deaths, PlayerData.get_fragment_count(), PlayerData.score]


func _on_menu_pressed() -> void:
	hide_end_screen()
	if SceneManager and SceneManager.has_method("goto_main_menu"):
		SceneManager.goto_main_menu()
	else:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
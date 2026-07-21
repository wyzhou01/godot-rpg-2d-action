extends CanvasLayer
## 结束画面（通关后显示）
##
## 玩家通关 Chapter 7 → game_complete 触发

@onready var title_label: Label = $CenterContainer/VBox/Title
@onready var stats_label: Label = $CenterContainer/VBox/Stats
@onready var menu_button: Button = $CenterContainer/VBox/MenuButton
@onready var settings_button: Button = $CenterContainer/VBox/SettingsButton

var _settings_menu: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings)
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


func _on_settings() -> void:
	# V2.4: 实例化 SettingsMenu (只一个实例)
	if _settings_menu and is_instance_valid(_settings_menu):
		return
	var settings_scene = preload("res://scenes/ui/settings_menu.tscn")
	_settings_menu = settings_scene.instantiate()
	add_child(_settings_menu)
	if _settings_menu.has_signal("closed"):
		_settings_menu.closed.connect(_on_settings_closed, CONNECT_ONE_SHOT)


func _on_settings_closed() -> void:
	if _settings_menu and is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
		_settings_menu = null
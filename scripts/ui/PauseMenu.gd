extends CanvasLayer
## 暂停菜单
##
## 按 Esc 暂停/继续
## 半透明黑遮罩 + 3 个按钮：继续 / 重置章节 / 退出主菜单

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

var _is_paused: bool = false
var _input_was_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 默认隐藏
	overlay.visible = false
	panel.visible = false
	# 等一帧确保子节点就绪
	await get_tree().process_frame
	# 连接按钮
	if resume_button and resume_button.has_signal("pressed"):
		resume_button.pressed.connect(_on_resume)
	if restart_button and restart_button.has_signal("pressed"):
		restart_button.pressed.connect(_on_restart)
	if quit_button and quit_button.has_signal("pressed"):
		quit_button.pressed.connect(_on_quit)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _is_paused:
			resume()
		else:
			pause()


func pause() -> void:
	if _is_paused:
		return
	_is_paused = true
	get_tree().paused = true
	overlay.visible = true
	panel.visible = true


func resume() -> void:
	if not _is_paused:
		return
	_is_paused = false
	get_tree().paused = false
	overlay.visible = false
	panel.visible = false


func _on_resume() -> void:
	resume()


func _on_restart() -> void:
	# 重置当前关卡
	resume()
	var current = get_tree().current_scene
	if current:
		PlayerData.on_player_died()
		get_tree().reload_current_scene()


func _on_quit() -> void:
	resume()
	if SceneManager and SceneManager.has_method("goto_main_menu"):
		SceneManager.goto_main_menu()
	else:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func is_paused() -> bool:
	return _is_paused
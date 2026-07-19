extends CanvasLayer
## 存档/读档菜单（主菜单用）
##
## 显示 4 个存档位的状态，玩家点击 → 加载

@onready var panel: PanelContainer = $Panel
@onready var slot_buttons: Array = []
@onready var info_label: Label = $InfoLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	slot_buttons = [
		$VBox/Slot1Button,
		$VBox/Slot2Button,
		$VBox/Slot3Button,
		$VBox/AutoSlotButton,
	]
	for i in slot_buttons.size():
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func show_menu() -> void:
	panel.visible = true
	_refresh_slots()


func hide_menu() -> void:
	panel.visible = false


func _refresh_slots() -> void:
	for i in slot_buttons.size():
		var btn = slot_buttons[i]
		if not btn:
			continue
		if SaveSystem.has_save(i):
			var data = SaveSystem.load_save(i)
			var ch = data.get("current_chapter", 1)
			var deaths = data.get("deaths", 0)
			var fragments = data.get("fragments_collected", [])
			var time = data.get("playtime_seconds", 0.0)
			btn.text = "Slot %d\nCh%d · %d 死 · %d 碎片 · %.0fs" % [i+1, ch, deaths, fragments.size(), time]
		else:
			btn.text = "Slot %d\n[空]" % (i+1)


func _on_slot_pressed(slot: int) -> void:
	if not SaveSystem.has_save(slot):
		_new_game()
		return
	var data = SaveSystem.load_save(slot)
	if data.is_empty():
		return
	_apply_save_data(data)
	var scene_path = data.get("scene_path", "res://scenes/levels/chapter_1/chapter_1_intro.tscn")
	if SceneManager and SceneManager.has_method("transition_to_scene"):
		SceneManager.transition_to_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
	hide_menu()


func _new_game() -> void:
	PlayerData.reset_for_new_game()
	if SceneManager and SceneManager.has_method("transition_to_scene"):
		SceneManager.transition_to_scene("res://scenes/levels/chapter_1/chapter_1_intro.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels/chapter_1/chapter_1_intro.tscn")
	hide_menu()


func _apply_save_data(data: Dictionary) -> void:
	PlayerData.current_chapter = data.get("current_chapter", 1)
	PlayerData.current_hp = data.get("current_hp", PlayerData.max_hp)
	PlayerData.current_fp = data.get("current_fp", PlayerData.max_fp)
	PlayerData.deaths = data.get("deaths", 0)
	PlayerData.score = data.get("score", 0)
	PlayerData.fragments_collected = data.get("fragments_collected", []).duplicate()
	PlayerData.playtime_seconds = data.get("playtime_seconds", 0.0)


func _on_back_pressed() -> void:
	hide_menu()
	if get_parent() and get_parent().has_method("show_main_menu"):
		get_parent().show_main_menu()
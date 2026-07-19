## Simple Dialogue Manager (autoload)
##
## 自实现的轻量级对话系统（替代 Dialogic 插件，因为 Dialogic 2.0-Alpha 不兼容 Godot 4.6）
##
## 用法:
##   DialogueHelper.show("res://dialogs/chapter_1_boss_intro.json")
##   await DialogueHelper.dialogue_ended
##
## 对话文件格式 (.json):
## {
##   "lines": [
##     {"character": "Player", "text": "...", "expression": "normal"},
##     {"character": "Onyx", "text": "...", "expression": "dark"}
##   ],
##   "choices": [
##     {"text": "Option 1", "next_line": 0},
##     {"text": "Option 2", "next_line": 2}
##   ]
## }

extends Node

signal dialogue_started(timeline: String)
signal dialogue_line_shown(character: String, text: String)
signal dialogue_ended(timeline: String)
signal choice_made(choice_index: int)

var _current_timeline: String = ""
var _is_showing: bool = false
var _timeline_data: Dictionary = {}
var _line_index: int = 0
var _label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## 显示一个对话
func show(timeline_path: String) -> void:
	dialogue_started.emit(timeline_path)
	_is_showing = true
	_current_timeline = timeline_path
	_line_index = 0
	_load_timeline(timeline_path)
	_find_or_create_label()
	get_tree().paused = true
	# 显示第一行
	await _show_next_line()


func _load_timeline(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Dialogue timeline not found: " + path)
		_is_showing = false
		_end_dialogue()
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		_is_showing = false
		_end_dialogue()
		return
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json is Dictionary:
		_timeline_data = json
	else:
		push_error("Invalid dialogue JSON: " + path)
		_timeline_data = {}


func _find_or_create_label() -> void:
	_label = get_tree().root.get_node_or_null("DialogueLabel")
	if _label == null:
		# 创建一个 CanvasLayer + Label
		var layer = CanvasLayer.new()
		layer.name = "DialogueLayer"
		layer.layer = 100  # 最高层
		get_tree().root.add_child.call_deferred(layer)

		var panel = PanelContainer.new()
		panel.name = "DialoguePanel"
		panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		panel.offset_top = -200
		panel.offset_bottom = 0
		panel.modulate = Color(1, 1, 1, 0.95)
		layer.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.name = "VBox"
		panel.add_child(vbox)

		var char_label = Label.new()
		char_label.name = "CharacterLabel"
		char_label.add_theme_font_size_override("font_size", 24)
		char_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
		vbox.add_child(char_label)

		var text_label = Label.new()
		text_label.name = "TextLabel"
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(text_label)

		_label = text_label
		_dialogue_panel = panel
		_character_label = char_label


var _dialogue_panel: PanelContainer = null
var _character_label: Label = null


func _show_next_line() -> void:
	if not _is_showing:
		return
	if _timeline_data.is_empty() or not _timeline_data.has("lines"):
		_end_dialogue()
		return

	var lines: Array = _timeline_data["lines"]
	if _line_index >= lines.size():
		_end_dialogue()
		return

	var line: Dictionary = lines[_line_index]
	var character = line.get("character", "???")
	var text = line.get("text", "")
	var expression = line.get("expression", "normal")

	# 显示在 label
	if _label:
		_label.text = "[%s] %s" % [character, text]
	if _character_label:
		_character_label.text = character
	dialogue_line_shown.emit(character, text)

	_line_index += 1

	# 等待玩家按键
	await _wait_for_input()
	if not _is_showing:
		return  # 可能 _end_dialogue 被调用了

	# 检查是否有 choices
	if line.has("choices") and _line_index == lines.size():
		# 显示选择
		await _show_choices(line["choices"])


func _show_choices(choices: Array) -> void:
	# 简化版：自动选第一个（30% 概率选第二个，演示用）
	# TODO: 真正的选择 UI
	choice_made.emit(0)
	if choices.size() > 0:
		var choice = choices[0]
		if choice.has("next_line"):
			_line_index = choice["next_line"]


func _wait_for_input() -> void:
	# 等待空格/回车/鼠标点击
	while _is_showing:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			return


func _end_dialogue() -> void:
	_is_showing = false
	get_tree().paused = false
	if _dialogue_panel and is_instance_valid(_dialogue_panel.get_parent()):
		_dialogue_panel.get_parent().queue_free()
		_dialogue_panel = null
		_label = null
		_character_label = null
	dialogue_ended.emit(_current_timeline)
	_current_timeline = ""


## 跳过当前对话
func skip() -> void:
	if _is_showing:
		_end_dialogue()

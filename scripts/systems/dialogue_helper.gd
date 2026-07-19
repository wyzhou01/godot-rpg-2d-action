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
##     {"character": "Player", "text": "...", "expression": "normal"}
##   ]
## }

extends Node
## 关键修复：process_mode = ALWAYS 让 _input 在任何时候都响应
## 不使用 get_tree().paused（会冻结 _process 推进）
## 直接用 _input 处理 ui_accept

signal dialogue_started(timeline: String)
signal dialogue_line_shown(character: String, text: String)
signal dialogue_ended(timeline: String)
signal choice_made(choice_index: int)

const ADVANCE_INPUT := "ui_accept"

var _current_timeline: String = ""
var _is_showing: bool = false
var _timeline_data: Dictionary = {}
var _line_index: int = 0
var _label: Label = null
var _dialogue_panel: PanelContainer = null
var _character_label: Label = null
var _hint_label: Label = null
var _dialogue_layer: CanvasLayer = null


func _ready() -> void:
	# ALWAYS：即使其他节点 paused，DialogueHelper 仍处理输入
	process_mode = Node.PROCESS_MODE_ALWAYS


## 显示一个对话
func show(timeline_path: String) -> void:
	if _is_showing:
		# 强制清理旧状态
		_is_showing = false
		if _dialogue_layer and is_instance_valid(_dialogue_layer):
			_dialogue_layer.queue_free()
		_dialogue_layer = null
		_dialogue_panel = null
		_label = null
		_character_label = null
		_hint_label = null
	_is_showing = true
	_current_timeline = timeline_path
	_line_index = 0
	_load_timeline(timeline_path)
	if _timeline_data.is_empty() or not _timeline_data.has("lines") or _timeline_data["lines"].is_empty():
		# 立即结束（无内容）
		_is_showing = false
		dialogue_ended.emit(_current_timeline)
		_current_timeline = ""
		return
	dialogue_started.emit(_current_timeline)
	_setup_ui()
	# 显示第一行
	_show_current_line()


func _load_timeline(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Dialogue timeline not found: " + path)
		_timeline_data = {}
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		_timeline_data = {}
		return
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json is Dictionary:
		_timeline_data = json
	else:
		push_error("Invalid dialogue JSON: " + path)
		_timeline_data = {}


func _setup_ui() -> void:
	# 清理旧的
	if _dialogue_layer and is_instance_valid(_dialogue_layer):
		_dialogue_layer.queue_free()
	
	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.name = "DialogueLayer"
	_dialogue_layer.layer = 100
	_dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_dialogue_layer)
	
	# 半透明黑色背景遮罩
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogue_layer.add_child(overlay)
	
	# 底部对话面板
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.offset_left = 100
	_dialogue_panel.offset_right = -100
	_dialogue_panel.offset_top = -220
	_dialogue_panel.offset_bottom = -20
	_dialogue_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# 半透明背景
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_color = Color(0.8, 0.7, 0.3, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_dialogue_panel.add_theme_stylebox_override("panel", style)
	_dialogue_layer.add_child(_dialogue_panel)
	
	var vbox := VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogue_panel.add_child(vbox)
	
	_character_label = Label.new()
	_character_label.add_theme_font_size_override("font_size", 24)
	_character_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	_character_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_character_label)
	
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(0, 80)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_label)
	
	_hint_label = Label.new()
	_hint_label.text = "[按空格/回车/点击继续 →]"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_hint_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_hint_label)


func _show_current_line() -> void:
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
	
	if _label:
		_label.text = text
	if _character_label:
		_character_label.text = character
	if _hint_label:
		var remaining = lines.size() - _line_index - 1
		_hint_label.text = "[按空格/回车继续] (%d 行剩余)" % remaining
	
	dialogue_line_shown.emit(character, text)
	_line_index += 1


## 全局输入处理（process_mode ALWAYS 让这里始终跑）
func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	if event.is_action_pressed(ADVANCE_INPUT) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance()


func _advance() -> void:
	if not _is_showing:
		return
	# 检查是否到达最后
	if _line_index >= _timeline_data.get("lines", []).size():
		_end_dialogue()
		return
	# 显示下一行
	_show_current_line()


func _end_dialogue() -> void:
	_is_showing = false
	if _dialogue_layer and is_instance_valid(_dialogue_layer):
		_dialogue_layer.queue_free()
	_dialogue_layer = null
	_dialogue_panel = null
	_label = null
	_character_label = null
	_hint_label = null
	var finished_timeline = _current_timeline
	_current_timeline = ""
	dialogue_ended.emit(finished_timeline)


## 跳过当前对话
func skip() -> void:
	if _is_showing:
		_end_dialogue()


func is_showing() -> bool:
	return _is_showing
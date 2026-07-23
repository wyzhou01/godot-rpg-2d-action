## Simple Dialogue Manager (autoload)
##
## 自实现的轻量级对话系统（替代 Dialogic 插件）
##
## 用法:
##   DialogueHelper.show("res://dialogs/chapter_1_intro.json")
##   await DialogueHelper.dialogue_ended

extends Node
## 关键修复：
## 1. process_mode = ALWAYS 让 _input 始终响应
## 2. UI 用 call_deferred 添加（避免在 _ready 中 add_child 失败）
## 3. _setup_ui 改为 async，await 添加完成再显示第一行
## 4. 不使用 get_tree().paused（会冻结）

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
	process_mode = Node.PROCESS_MODE_ALWAYS


## 显示一个对话（async，UI 创建后再显示第一行）
func show(timeline_path: String) -> void:
	if _is_showing:
		# 强制清理旧状态（防御性）
		_force_cleanup()
	
	_is_showing = true
	_current_timeline = timeline_path
	_line_index = 0
	_load_timeline(timeline_path)
	
	if _timeline_data.is_empty() or not _timeline_data.has("lines") or _timeline_data["lines"].is_empty():
		_is_showing = false
		dialogue_ended.emit(_current_timeline)
		_current_timeline = ""
		return
	
	dialogue_started.emit(_current_timeline)
	
	# 异步创建 UI — 必须用 await process_frame
	# 因为 _setup_ui 用 call_deferred 实际添加到 tree
	_setup_ui()
	await get_tree().process_frame  # 等一帧让 add_child 生效
	await get_tree().process_frame  # 再等一帧确保子节点就绪
	
	# 现在 label 真的有效，显示第一行
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
	# 清理旧的（如果还在）
	if _dialogue_layer and is_instance_valid(_dialogue_layer):
		_dialogue_layer.queue_free()
		_dialogue_layer = null
	_dialogue_panel = null
	_label = null
	_character_label = null
	_hint_label = null
	
	# 创建 CanvasLayer（顶级 UI，不受场景暂停影响）
	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.name = "DialogueLayer"
	_dialogue_layer.layer = 100
	_dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 用 call_deferred 添加到 root（避免在 _ready 中 add_child 失败）
	get_tree().root.add_child.call_deferred(_dialogue_layer)
	
	# 半透明黑色背景遮罩
	var overlay := ColorRect.new()
	overlay.name = "DialogueOverlay"
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 底部对话面板
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.offset_left = 100
	_dialogue_panel.offset_right = -100
	_dialogue_panel.offset_top = -220
	_dialogue_panel.offset_bottom = -20
	_dialogue_panel.process_mode = Node.PROCESS_MODE_ALWAYS
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
	
	# 先 add overlay 到 layer（必须先 layer 存在，但 layer 是 deferred）
	# 这里改顺序：先建 panel（独立），overlay 直接添加到 panel 内部
	# 简单：把 panel 作为 layer 的子节点，然后 panel 内放 vbox
	# 但 layer 是 deferred，所以 panel 也得 deferred
	# 折中：先同步 add overlay 到 layer（layer 还不在 tree 但 add_child 可以工作）
	_dialogue_layer.add_child(overlay)
	_dialogue_layer.add_child(_dialogue_panel)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogue_panel.add_child(vbox)
	
	_character_label = Label.new()
	_character_label.name = "CharacterLabel"
	_character_label.add_theme_font_size_override("font_size", 24)
	_character_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	_character_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_character_label)
	
	_label = Label.new()
	_label.name = "TextLabel"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(0, 80)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_label)
	
	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = "[按空格/回车继续]"
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
	else:
		push_warning("DialogueHelper: _label is null, skipping line")
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


## 修复 V2.5: 兑底修复 Input.action_press 不产生 InputEvent 的场景
## (修复)
func _process(_delta: float) -> void:
	if not _is_showing:
		return
	if Input.is_action_just_pressed(ADVANCE_INPUT):
		_advance()


func _advance() -> void:
	if not _is_showing:
		return
	if _line_index >= _timeline_data.get("lines", []).size():
		_end_dialogue()
		return
	_show_current_line()


func _force_cleanup() -> void:
	_is_showing = false
	if _dialogue_layer and is_instance_valid(_dialogue_layer):
		_dialogue_layer.queue_free()
	_dialogue_layer = null
	_dialogue_panel = null
	_label = null
	_character_label = null
	_hint_label = null


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

extends CanvasLayer
## 教学提示（Chapter 1 第一次进入时显示）
##
## 显示 5 秒后自动消失，按任意键立即消失

@onready var label: Label = $Label

var _hint_text: String = ""
var _timer: float = 0.0
var _duration: float = 5.0
var _can_dismiss: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_hint(text: String, duration: float = 5.0) -> void:
	_hint_text = text
	_duration = duration
	_timer = 0.0
	if label:
		label.text = text
	visible = true


func hide_hint() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_timer += delta
	if _timer >= _duration:
		hide_hint()


func _input(event: InputEvent) -> void:
	if visible and _can_dismiss and event.is_pressed():
		hide_hint()
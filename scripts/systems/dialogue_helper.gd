## Dialogic 集成辅助（autoload）
##
## 用法:
##   DialogueHelper.play("res://dialogs/greyr1_intro.dlg")
##   await DialogueHelper.dialogue_ended

signal dialogue_started(timeline: String)
signal dialogue_ended(timeline: String)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## 播放一个 Dialogic 时间线
func play(timeline_path: String) -> void:
	dialogue_started.emit(timeline_path)
	# Dialogic 是自动注册的 autoload
	Dialogic.start(timeline_path)
	await Dialogic.timeline_ended
	dialogue_ended.emit(timeline_path)


## 播放 + 暂停游戏
func play_and_pause(timeline_path: String) -> void:
	get_tree().paused = true
	dialogue_started.emit(timeline_path)
	Dialogic.start(timeline_path)
	await Dialogic.timeline_ended
	get_tree().paused = false
	dialogue_ended.emit(timeline_path)


## 跳转到指定 label（用于分支对话）
func jump_to_label(label: String) -> void:
	Dialogic.jump_to_label(label)

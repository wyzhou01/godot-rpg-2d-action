extends SceneTree

## 端到端测试：跑 chapter_1_intro，验证 DialogueHelper

var dh: Node = null


func _init():
	# 监听信号
	dh = root.get_node_or_null("DialogueHelper")
	if dh == null:
		print("[FAIL] DialogueHelper autoload not found!")
		quit()
		return
	
	dh.dialogue_started.connect(_on_started)
	dh.dialogue_line_shown.connect(_on_line)
	dh.dialogue_ended.connect(_on_ended)
	
	print("[TEST] DialogueHelper found: ", dh)
	print("[TEST] Loading scene...")
	var scene = load("res://scenes/levels/chapter_1/chapter_1_intro.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	# 等 4 秒让 intro 启动
	await create_timer(4.0).timeout
	
	print("=== STATE ===")
	print("is_showing=", dh._is_showing)
	print("label=", dh._label)
	print("line_index=", dh._line_index)
	if dh._timeline_data:
		print("lines count=", dh._timeline_data.get("lines", []).size())
	
	print("=== Simulating Enter x5 ===")
	for i in 5:
		Input.action_press("ui_accept")
		await create_timer(0.3).timeout
		Input.action_release("ui_accept")
		print("After press ", i, ": is_showing=", dh._is_showing, " line_index=", dh._line_index, " tree_paused=", paused)
		if not dh._is_showing:
			break
	
	quit()


func _on_started(timeline: String) -> void:
	print("[SIGNAL] dialogue_started: ", timeline)


func _on_line(character: String, text: String) -> void:
	print("[SIGNAL] line: ", character, " → ", text.substr(0, 50))


func _on_ended(timeline: String) -> void:
	print("[SIGNAL] dialogue_ended: ", timeline)
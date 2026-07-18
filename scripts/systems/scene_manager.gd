## 场景管理器（autoload）
##
## 职责:
##   - 关卡切换（淡入淡出）
##   - 玩家位置存档/恢复
##   - 死亡 → 自动从存档点复活

signal scene_changing(from: String, to: String)
signal scene_changed(path: String)

# 关卡链（按顺序）
const LEVEL_CHAIN := [
	"res://scenes/levels/chapter_1/chapter_1_intro.tscn",
	"res://scenes/levels/chapter_1/chapter_1_combat.tscn",
	"res://scenes/levels/chapter_1/chapter_1_boss.tscn",
	# TODO: 其余章节
]

var fade_overlay: ColorRect
var tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 创建淡入淡出覆盖层
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.size = get_viewport().get_visible_rect().size
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false
	fade_overlay.z_index = 9999
	get_tree().root.add_child.call_deferred(fade_overlay)


# ===== 淡入淡出 =====
func fade_to_black(duration: float = 0.8) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	await tween.finished


func fade_from_black(duration: float = 0.8) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	await tween.finished
	fade_overlay.visible = false


# ===== 场景切换 =====
func transition_to_scene(path: String) -> void:
	var current_path = get_tree().current_scene.scene_file_path
	scene_changing.emit(current_path, path)
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await fade_from_black()
	scene_changed.emit(path)


func goto_main_menu() -> void:
	transition_to_scene("res://ui/main_menu.tscn")


func goto_next_level() -> void:
	var current_path = get_tree().current_scene.scene_file_path
	for i in LEVEL_CHAIN.size():
		if LEVEL_CHAIN[i] == current_path and i + 1 < LEVEL_CHAIN.size():
			transition_to_scene(LEVEL_CHAIN[i + 1])
			return
	# 已是最后一关 → 跳转到 main menu
	goto_main_menu()


# ===== 玩家死亡处理 =====
func on_player_died() -> void:
	# 1 秒后自动从存档点复活
	await get_tree().create_timer(1.0).timeout
	# TODO: 触发自动存档
	# TODO: 跳转到当前关卡
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs:
		gs.player_death()
	# 简单实现：重载当前场景
	var current_path = get_tree().current_scene.scene_file_path
	transition_to_scene(current_path)

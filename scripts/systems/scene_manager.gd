## 场景管理器（autoload）
##
## 职责:
##   - 关卡切换（淡入淡出）
##   - 玩家位置存档/恢复
##   - 死亡 → 自动从存档点复活
##   - BGM 播放（每章不同）

extends Node

signal scene_changing(from: String, to: String)
signal scene_changed(path: String)

# 关卡链（按顺序）
const LEVEL_CHAIN := [
	"res://scenes/levels/chapter_1/chapter_1_intro.tscn",
	"res://scenes/levels/chapter_1/chapter_1_combat.tscn",
	"res://scenes/levels/chapter_1/chapter_1_boss.tscn",
	"res://scenes/levels/chapter_2/chapter_2_intro.tscn",
	"res://scenes/levels/chapter_2/chapter_2_boss.tscn",
	"res://scenes/levels/chapter_3/chapter_3_intro.tscn",
	"res://scenes/levels/chapter_3/chapter_3_boss.tscn",
	"res://scenes/levels/chapter_4/chapter_4_intro.tscn",
	"res://scenes/levels/chapter_4/chapter_4_boss.tscn",
	"res://scenes/levels/chapter_5/chapter_5_intro.tscn",
	"res://scenes/levels/chapter_5/chapter_5_boss.tscn",
	"res://scenes/levels/chapter_6/chapter_6_intro.tscn",
	"res://scenes/levels/chapter_6/chapter_6_boss.tscn",
	"res://scenes/levels/chapter_7/chapter_7_intro.tscn",
	"res://scenes/levels/chapter_7/chapter_7_boss.tscn",
]

# 关卡路径 → 章节号（用于 BGM 切换）
const SCENE_TO_CHAPTER := {
	"chapter_1_intro.tscn": 1,
	"chapter_1_combat.tscn": 1,
	"chapter_1_boss.tscn": 1,
	"chapter_2_intro.tscn": 2,
	"chapter_2_boss.tscn": 2,
	"chapter_3_intro.tscn": 3,
	"chapter_3_boss.tscn": 3,
	"chapter_4_intro.tscn": 4,
	"chapter_4_boss.tscn": 4,
	"chapter_5_intro.tscn": 5,
	"chapter_5_boss.tscn": 5,
	"chapter_6_intro.tscn": 6,
	"chapter_6_boss.tscn": 6,
	"chapter_7_intro.tscn": 7,
	"chapter_7_boss.tscn": 7,
}

var fade_overlay: ColorRect
var tween: Tween
var _bgm: Node = null
var _current_chapter: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fade()
	_setup_bgm()


func _setup_fade() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.size = get_viewport().get_visible_rect().size
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false
	fade_overlay.z_index = 127
	get_tree().root.add_child.call_deferred(fade_overlay)


func _setup_bgm() -> void:
	var BgmGen = load("res://scripts/systems/bgm_generator.gd")
	if BgmGen:
		_bgm = BgmGen.new()
		_bgm.name = "BGMGenerator"
		add_child(_bgm)


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
	_update_bgm_for_scene(path)
	await fade_from_black()
	scene_changed.emit(path)


func _update_bgm_for_scene(path: String) -> void:
	# 根据场景路径提取章节号
	for key in SCENE_TO_CHAPTER:
		if key in path:
			var chapter = SCENE_TO_CHAPTER[key]
			if chapter != _current_chapter:
				_current_chapter = chapter
				play_bgm_for_chapter(chapter)
			return


func play_bgm_for_chapter(chapter: int) -> void:
	if _bgm and _bgm.has_method("play_chapter"):
		_bgm.play_chapter(chapter)


func goto_main_menu() -> void:
	transition_to_scene("res://ui/main_menu.tscn")


func goto_next_level() -> void:
	var current_path = get_tree().current_scene.scene_file_path
	for i in LEVEL_CHAIN.size():
		if LEVEL_CHAIN[i] == current_path:
			if i + 1 < LEVEL_CHAIN.size():
				transition_to_scene(LEVEL_CHAIN[i + 1])
			else:
				# 最后一关 → 返回主菜单
				goto_main_menu()
			return
	goto_main_menu()


# ===== 玩家死亡处理 =====
func on_player_died() -> void:
	# 必须 ready 之后才能用 get_tree()
	if not is_inside_tree():
		return
	# 1 秒后自动从存档点复活
	await get_tree().create_timer(1.0).timeout
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs:
		gs.player_death()
	# 简单实现：重载当前场景
	var current_path = get_tree().current_scene.scene_file_path
	transition_to_scene(current_path)

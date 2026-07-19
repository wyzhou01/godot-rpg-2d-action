class_name HUD extends CanvasLayer
## HUD 界面（HP/FP/7 碎片/死亡计数/章节名）
## 挂在场景里，自动订阅 Player 的 Stats 节点和 PlayerData

@onready var hp_bar: ProgressBar = $HPBar
@onready var fp_bar: ProgressBar = $FPBar
@onready var skill_icons: HBoxContainer = $SkillIcons
@onready var fragment_grid: HBoxContainer = $FragmentGrid
@onready var death_label: Label = $DeathLabel
@onready var chapter_label: Label = $ChapterLabel

# 7 个 Fragment 状态格
var _fragment_cells: Array = []  # [ColorRect, ColorRect, ...]
var _chapter_names := {
	1: "Chapter 1 · 圣剑骑士团",
	2: "Chapter 2 · 雪山修道院",
	3: "Chapter 3 · 腐木森林",
	4: "Chapter 4 · 黄金圣殿",
	5: "Chapter 5 · 烈焰之心",
	6: "Chapter 6 · 翡翠德鲁伊",
	7: "Chapter 7 · 黑曜石王座",
}


func _ready() -> void:
	# 等待玩家准备好
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_connect_player(player)
	
	# 初始化碎片格
	_init_fragment_grid()
	
	# 连接 PlayerData
	if PlayerData:
		PlayerData.updated.connect(_on_player_data_updated)
		PlayerData.reset.connect(_on_player_data_updated)
		PlayerData.died.connect(_on_player_died)
		_on_player_data_updated()


func _connect_player(player: Node) -> void:
	# HP/FP 绑定
	var stats = player.get_node_or_null("Stats")
	if stats:
		stats.health_increased.connect(_on_health_changed.bind(stats))
		stats.health_decreased_but_not_depleted.connect(_on_health_changed.bind(stats))
		# 初始值
		hp_bar.max_value = stats.max_health
		hp_bar.value = stats.health


func _init_fragment_grid() -> void:
	if fragment_grid == null:
		return
	# 创建 7 个 cell
	_fragment_cells.clear()
	for i in 7:
		var cell = ColorRect.new()
		cell.custom_minimum_size = Vector2(32, 32)
		cell.color = Color(0.2, 0.2, 0.2, 0.6)  # 未收集 = 暗
		fragment_grid.add_child(cell)
		_fragment_cells.append(cell)


func _on_health_changed(stats: Stats) -> void:
	if hp_bar:
		hp_bar.value = stats.health
		# 红屏闪烁
		if hp_bar.value < hp_bar.max_value:
			_flash_screen()


func _on_player_data_updated() -> void:
	# 更新碎片显示
	_update_fragments_display()
	# 更新死亡计数
	if death_label:
		death_label.text = "☠ %d" % PlayerData.deaths
	# 更新章节名
	if chapter_label and PlayerData.current_chapter in _chapter_names:
		chapter_label.text = _chapter_names[PlayerData.current_chapter]


func _update_fragments_display() -> void:
	if _fragment_cells.size() != 7:
		return
	for i in 7:
		var fragment_id = "ch%d" % (i + 1)
		if PlayerData.has_fragment(fragment_id):
			_fragment_cells[i].color = Color(1, 0.85, 0.3, 1)  # 已收集 = 金
		else:
			_fragment_cells[i].color = Color(0.2, 0.2, 0.2, 0.6)  # 未收集 = 暗


func _on_player_died() -> void:
	# 死亡时屏幕短暂变红
	var flash = ColorRect.new()
	flash.color = Color(0.8, 0, 0, 0.5)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)


func _flash_screen() -> void:
	# 简单红屏闪烁（受击时）
	var flash = ColorRect.new()
	flash.color = Color(1, 0.3, 0.3, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
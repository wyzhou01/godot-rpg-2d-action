class_name HUD extends CanvasLayer
## HUD 界面（HP / FP / 技能冷却）
## 挂在场景里，自动订阅 Player 的 Stats 节点

@onready var hp_bar: ProgressBar = $HPBar
@onready var fp_bar: ProgressBar = $FPBar
@onready var skill_icons: HBoxContainer = $SkillIcons


func _ready() -> void:
	# 等待玩家准备好
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_connect_player(player)


func _connect_player(player: Node) -> void:
	# HP/FP 绑定
	var stats = player.get_node_or_null("Stats")
	if stats:
		stats.health_increased.connect(_on_health_changed.bind(stats))
		stats.health_decreased_but_not_depleted.connect(_on_health_changed.bind(stats))
		# 初始值
		hp_bar.max_value = stats.max_health
		hp_bar.value = stats.health

	# FP（如果没有 Stats 节点，自行管理）
	# TODO: 添加 FP 节点


func _on_health_changed(stats: Stats) -> void:
	hp_bar.value = stats.health
	# 红屏闪烁（受击时）
	if hp_bar.value < hp_bar.max_value:
		_flash_screen()


func _flash_screen() -> void:
	# 红屏闪烁（受击时）— CanvasLayer 不支持 modulate，用动态创建 ColorRect
	var flash = ColorRect.new()
	flash.color = Color(1, 0.3, 0.3, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

extends CanvasLayer
## Settings UI (Phase 4.3 — V2.4)
##
## 3 个音量 slider (Master / Music / SFX) + 全屏 toggle + 返回按钮
## 接入 AudioServer bus 音量 + DisplayServer 全屏切换
##
## 用法: 实例化本场景 (add_child) → 用户操作 → emit closed 信号 → 调用方负责清理
##
## 修复 V2.4:
## - Master bus 是 AudioServer 默认 bus idx 0, 永远存在
## - Music / SFX bus 运行时检查, 不存在则 add_bus
## - Maaacks 插件会用 "Music" bus 放背景乐
## - 音量用 linear→dB 转换 (0.0=静音, 1.0=0dB, 0.5=-6dB)

signal closed

const SETTINGS_CONFIG_PATH := "user://settings.cfg"

@onready var master_slider: HSlider = $Panel/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXRow/SFXSlider
@onready var master_label: Label = $Panel/VBox/MasterRow/ValueLabel
@onready var music_label: Label = $Panel/VBox/MusicRow/ValueLabel
@onready var sfx_label: Label = $Panel/VBox/SFXRow/ValueLabel
@onready var fullscreen_check: CheckButton = $Panel/VBox/FullscreenRow/FullscreenCheck
@onready var back_button: Button = $Panel/VBox/BackButton

var _master_bus_idx: int = -1
var _music_bus_idx: int = -1
var _sfx_bus_idx: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能操作
	_master_bus_idx = _ensure_bus("Master", 0)
	_music_bus_idx = _ensure_bus("Music")
	_sfx_bus_idx = _ensure_bus("SFX")
	_load_settings()
	_connect_signals()


func _connect_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func _ensure_bus(bus_name: String, hint_idx: int = -1) -> int:
	# 检查 bus 是否已存在, 不存在则 add_bus
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == bus_name:
			return i
	# 不存在, 添加 (新 bus 是最后一个, idx = count)
	AudioServer.add_bus()
	var new_idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(new_idx, bus_name)
	return new_idx


# ===== 音量处理 =====

func _on_master_changed(value: float) -> void:
	if _master_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_master_bus_idx, linear_to_db(value))
	if master_label:
		master_label.text = "%d%%" % int(value * 100)
	_save_settings()


func _on_music_changed(value: float) -> void:
	if _music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(value))
	if music_label:
		music_label.text = "%d%%" % int(value * 100)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	if _sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_sfx_bus_idx, linear_to_db(value))
	if sfx_label:
		sfx_label.text = "%d%%" % int(value * 100)
	_save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_back_pressed() -> void:
	_save_settings()
	closed.emit()


# ===== 持久化 =====

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_CONFIG_PATH)
	if err != OK:
		# 首次启动: 用当前值 (AudioServer 默认 0 dB = 1.0 linear)
		if master_slider:
			master_slider.value = 1.0
			master_label.text = "100%"
		if music_slider:
			music_slider.value = 1.0
			music_label.text = "100%"
		if sfx_slider:
			sfx_slider.value = 1.0
			sfx_label.text = "100%"
		# 全屏状态从 DisplayServer 读
		if fullscreen_check:
			fullscreen_check.button_pressed = (
				DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			)
		return
	if master_slider:
		var v: float = cfg.get_value("audio", "master_volume", 1.0)
		master_slider.value = v
		AudioServer.set_bus_volume_db(_master_bus_idx, linear_to_db(v))
		master_label.text = "%d%%" % int(v * 100)
	if music_slider:
		var v: float = cfg.get_value("audio", "music_volume", 1.0)
		music_slider.value = v
		AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(v))
		music_label.text = "%d%%" % int(v * 100)
	if sfx_slider:
		var v: float = cfg.get_value("audio", "sfx_volume", 1.0)
		sfx_slider.value = v
		AudioServer.set_bus_volume_db(_sfx_bus_idx, linear_to_db(v))
		sfx_label.text = "%d%%" % int(v * 100)
	if fullscreen_check:
		var v: bool = cfg.get_value("display", "fullscreen", false)
		fullscreen_check.button_pressed = v
		# 应用全屏 (启动时不应用 — 让 DisplayServer 决定)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_CONFIG_PATH)  # 容错: 加载已有的
	if master_slider:
		cfg.set_value("audio", "master_volume", master_slider.value)
	if music_slider:
		cfg.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider:
		cfg.set_value("audio", "sfx_volume", sfx_slider.value)
	if fullscreen_check:
		cfg.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	cfg.save(SETTINGS_CONFIG_PATH)

## 存档系统（autoload）
##
## 提供 3 个手动存档位 + 1 个自动存档位
## 用 JSON 格式（人类可读 / 调试方便）

extends Node
const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 4  # 0-2 手动, 3 自动

signal save_completed(slot: int)
signal load_completed(slot: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 确保存档目录存在
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ===== 保存 =====
static func save_game(slot: int, data: Dictionary) -> bool:
	if slot < 0 or slot >= 4:
		push_error("SaveSystem: invalid slot %d" % slot)
		return false
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path = SAVE_DIR + "save_%d.json" % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: failed to open %s for write" % path)
		return false
	# 添加时间戳
	data["save_timestamp"] = Time.get_unix_time_from_system()
	data["save_version"] = "1.0"
	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
	return true


# ===== 加载 =====
static func load_save(slot: int) -> Dictionary:
	if slot < 0 or slot >= 4:
		push_error("SaveSystem: invalid slot %d" % slot)
		return {}
	var path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: failed to open %s for read" % path)
		return {}
	var json_text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_text)
	if data is Dictionary:
		return data
	return {}


# ===== 删除 =====
static func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= 4:
		return false
	var path = SAVE_DIR + "save_%d.json" % slot
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		return err == OK
	return true


# ===== 检查存档存在 =====
static func has_save(slot: int) -> bool:
	if slot < 0 or slot >= 4:
		return false
	return FileAccess.file_exists(SAVE_DIR + "save_%d.json" % slot)


# ===== 获取所有存档元信息 =====
static func get_all_saves() -> Array:
	var result = []
	for slot in 4:
		if has_save(slot):
			var data = load_save(slot)
			result.append({
				"slot": slot,
				"chapter": data.get("current_chapter", 1),
				"play_time": data.get("total_play_time", 0.0),
				"timestamp": data.get("save_timestamp", 0),
				"shards": data.get("collected_shards", []),
				"deaths": data.get("total_deaths", 0),
			})
		else:
			result.append({
				"slot": slot,
				"empty": true,
			})
	return result


# ===== 便利方法 =====
static func save_current_game() -> bool:
	# 保存到 slot 3（自动存档）
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		push_error("SaveSystem: GameState autoload not found")
		return false
	return save_game(3, gs.get_save_data())


static func save_to_slot(slot: int) -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		return false
	return save_game(slot, gs.get_save_data())

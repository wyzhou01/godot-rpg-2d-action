## 全局游戏状态（autoload）
##
## 职责:
##   - 玩家跨场景数据（HP/FP/位置/章节进度/碎片/技能）
##   - 全局事件触发器（碎片收集 / 章节完成）
##   - 与 SaveSystem 交互

# 玩家当前状态
extends Node
var current_chapter: int = 1
var max_hp: int = 100
var current_hp: int = 100
var max_fp: int = 50
var current_fp: int = 50
var player_position: Vector2 = Vector2.ZERO
var current_level_path: String = ""

# 进度
var collected_shards: Array[int] = []  # 已收集的碎片 ID（1-7）
var defeated_bosses: Array[String] = []  # 已击败的 boss 名字
var unlocked_abilities: Array[String] = []  # 已解锁技能
var dialogue_history: Dictionary = {}  # 对话历史（影响后续对话）

# 统计
var total_play_time: float = 0.0
var total_enemies_killed: int = 0
var total_deaths: int = 0

signal shard_collected(shard_id: int)
signal boss_defeated(boss_name: String)
signal chapter_changed(new_chapter: int)
signal player_died


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 启动时尝试加载默认存档
	var save = SaveSystem.load_save(0)
	if save:
		_apply_save(save)


func _process(delta: float) -> void:
	total_play_time += delta


# ===== 碎片收集 =====
func collect_shard(shard_id: int) -> void:
	if shard_id in collected_shards:
		return
	collected_shards.append(shard_id)
	shard_collected.emit(shard_id)
	# 解锁新技能
	_unlock_shard_ability(shard_id)


func _unlock_shard_ability(shard_id: int) -> void:
	# 每个碎片解锁 1 个技能
	match shard_id:
		1: unlocked_abilities.append("war_cry")  # 战吼
		2: unlocked_abilities.append("magic_shield")  # 魔法盾
		3: unlocked_abilities.append("shadow_step")  # 瞬移
		4: unlocked_abilities.append("holy_smite")  # 圣击
		5: unlocked_abilities.append("flame_burst")  # 烈焰爆发
		6: unlocked_abilities.append("time_stop")  # 时间停止
		7: unlocked_abilities.append("ultimate_slash")  # 大招


# ===== Boss 击败 =====
func defeat_boss(boss_name: String) -> void:
	if boss_name in defeated_bosses:
		return
	defeated_bosses.append(boss_name)
	boss_defeated.emit(boss_name)


# ===== 章节切换 =====
func change_chapter(new_chapter: int) -> void:
	current_chapter = new_chapter
	chapter_changed.emit(new_chapter)
	# 满血满蓝（章节切换存档点）
	current_hp = max_hp
	current_fp = max_fp


# ===== 玩家死亡 =====
func player_death() -> void:
	total_deaths += 1
	player_died.emit()


# ===== 存档数据 =====
func get_save_data() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_fp": max_fp,
		"current_fp": current_fp,
		"player_position_x": player_position.x,
		"player_position_y": player_position.y,
		"current_level_path": current_level_path,
		"collected_shards": collected_shards,
		"defeated_bosses": defeated_bosses,
		"unlocked_abilities": unlocked_abilities,
		"dialogue_history": dialogue_history,
		"total_play_time": total_play_time,
		"total_enemies_killed": total_enemies_killed,
		"total_deaths": total_deaths,
	}


func _apply_save(save: Dictionary) -> void:
	current_chapter = save.get("current_chapter", 1)
	max_hp = save.get("max_hp", 100)
	current_hp = save.get("current_hp", 100)
	max_fp = save.get("max_fp", 50)
	current_fp = save.get("current_fp", 50)
	player_position = Vector2(save.get("player_position_x", 0), save.get("player_position_y", 0))
	current_level_path = save.get("current_level_path", "")
	collected_shards = save.get("collected_shards", [])
	defeated_bosses = save.get("defeated_bosses", [])
	unlocked_abilities = save.get("unlocked_abilities", [])
	dialogue_history = save.get("dialogue_history", {})
	total_play_time = save.get("total_play_time", 0.0)
	total_enemies_killed = save.get("total_enemies_killed", 0)
	total_deaths = save.get("total_deaths", 0)

func complete_game() -> void:
	# 7 个碎片都收集了
	if collected_shards.size() >= 7:
		var dh = Engine.get_main_loop().root.get_node_or_null("DialogueHelper")
		if dh and dh.has_method("show"):
			dh.show.call_deferred("res://dialogs/game_complete.json")

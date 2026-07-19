extends Node
## 难度平衡参数
##
## 调整玩家/敌人/Boss 的数值
## 单一源（single source of truth），方便改

# 玩家
const PLAYER_HP: int = 100
const PLAYER_FP: int = 50
const PLAYER_MOVE_SPEED: float = 220.0
const PLAYER_JUMP_VELOCITY: float = -450.0
const PLAYER_DASH_SPEED: float = 400.0
const PLAYER_DASH_DURATION: float = 0.2
const PLAYER_DASH_COOLDOWN: float = 1.0
const PLAYER_ATTACK_DAMAGE: int = 15
const PLAYER_ATTACK_RANGE: float = 60.0

# 敌人
const ENEMY_KNIGHT_HP: int = 30
const ENEMY_KNIGHT_DAMAGE: int = 8
const ENEMY_KNIGHT_SPEED: float = 60.0
const ENEMY_KNIGHT_DETECT_RANGE: float = 200.0

const ENEMY_ARCHER_HP: int = 20
const ENEMY_ARCHER_DAMAGE: int = 12
const ENEMY_ARCHER_SPEED: float = 40.0
const ENEMY_ARCHER_SHOOT_RANGE: float = 250.0

const ENEMY_MAGE_HP: int = 25
const ENEMY_MAGE_DAMAGE: int = 15
const ENEMY_MAGE_SPEED: float = 35.0
const ENEMY_MAGE_CAST_RANGE: float = 220.0

# Boss（每章 1 个）
const BOSS_HP_BY_CHAPTER: Dictionary = {
	1: 200, 2: 350, 3: 500,
	4: 700, 5: 900, 6: 1100, 7: 1500,
}
const BOSS_DAMAGE: int = 25
const BOSS_SPEED: float = 80.0
const BOSS_PHASE_THRESHOLDS: Array = [0.5, 0.25]  # 血量 < 50% 触发 phase 2, < 25% 触发 phase 3

# 关卡难度递增
const CHAPTER_ENEMY_COUNT: Dictionary = {
	1: 3, 2: 3, 3: 3,
	4: 4, 5: 4, 6: 4, 7: 5,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## 玩家升级时调用
func get_player_hp() -> int:
	return PLAYER_HP


## 获取 Boss HP（按章节）
func get_boss_hp(chapter: int) -> int:
	return BOSS_HP_BY_CHAPTER.get(chapter, 500)


## 获取关卡敌人数量
func get_enemy_count(chapter: int) -> int:
	return CHAPTER_ENEMY_COUNT.get(chapter, 3)
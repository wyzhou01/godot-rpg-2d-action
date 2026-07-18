class_name PlayerStats extends Resource

## 玩家属性配置（Resource 化，方便数值平衡）
## 用法: 在 player.tscn Inspector 里 Load Resource 选择 player_stats.tres

@export var max_hp: int = 100
@export var max_fp: int = 50
@export var attack_power: int = 10
@export var defense: int = 5
@export var move_speed: float = 220.0
@export var jump_velocity: float = -480.0
@export var dash_speed: float = 480.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var dash_iframe_duration: float = 0.2

## 战斗参数
@export var attack_combo_window: float = 0.15  # 连击窗口（s）
@export var attack_range: float = 80.0  # 剑攻击判定半径
@export var shield_parry_window: float = 0.3  # 盾反窗口（s）

## 战吼参数
@export var war_cry_radius: float = 100.0
@export var war_cry_fp_cost: int = 15
@export var war_cry_cooldown: float = 8.0
@export var war_cry_iframe_duration: float = 0.5

## 治疗参数
@export var heal_percent: float = 0.3
@export var heal_fp_cost: int = 20

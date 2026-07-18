class_name BossStats extends Resource

## Boss 数值配置（多阶段机制）

@export var boss_name: String = "Unknown Boss"
@export var chapter: int = 1
@export var max_hp: int = 200
@export var attack_power: int = 15
@export var move_speed: float = 100.0
@export var detection_range: float = 1000.0

## 阶段阈值（HP 百分比）
@export var phase_2_threshold: float = 0.66
@export var phase_3_threshold: float = 0.33

## 阶段技能（每个阶段独立）
@export var phase_1_skills: Array[String] = ["slash_combo", "shield_bash"]
@export var phase_2_skills: Array[String] = ["slash_combo", "fireball", "teleport"]
@export var phase_3_skills: Array[String] = ["ultimate_cast", "summon_minions", "rage_slash"]

## 狂暴
@export var rage_speed_multiplier: float = 1.5
@export var rage_attack_multiplier: float = 1.3

## 掉落
@export var drops_shard: bool = true
@export var shard_id: int = 1

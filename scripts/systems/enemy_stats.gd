class_name EnemyStats extends Resource

## 敌人数值配置（Resource 化）
## 用法: 在 enemy.tscn Inspector 里 Load Resource 选择 enemy_stats.tres

@export var max_hp: int = 8
@export var attack_power: int = 1
@export var defense: int = 0
@export var move_speed: float = 50.0
@export var detection_range: float = 800.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.0

## 远程敌人专属
@export var is_ranged: bool = false
@export var projectile_speed: float = 600.0
@export var projectile_range: float = 1800.0
@export var projectile_scene: PackedScene

## 召唤/特殊敌人
@export var can_summon: bool = false
@export var summon_cooldown: float = 5.0
@export var summon_scene: PackedScene

## 格挡/闪避
@export var block_chance: float = 0.0
@export var dodge_chance: float = 0.0

## 群体仇恨
@export var is_flying: bool = false
@export var is_swarm: bool = false
@export var self_destruct_on_contact: bool = false
@export var self_destruct_damage: int = 3
@export var self_destruct_radius: float = 60.0

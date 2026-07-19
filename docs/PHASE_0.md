# Phase 0: 架构重构详细任务

> **目标**：把现有代码改成"真游戏"基础架构
> **预计时间**：1-3 天（每天 1-2 小时）

---

## 任务 0.1：Actor 基类（30 分钟）

### 文件
- `scripts/core/Actor.gd`

### 代码模板
```gdscript
extends CharacterBody2D
class_name Actor
## 所有角色的基类（Player/Enemy/Boss 统一接口）

@export var speed: Vector2 = Vector2(200, 500)
@export var gravity: float = 1500.0

var _velocity: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		_velocity.y += gravity * delta


func move(snap: Vector2 = Vector2.ZERO) -> void:
	# 子类重写移动逻辑
	pass


## 给子类调用：水平移动 + 撞墙反弹
func move_with_bounce() -> void:
	_velocity = move_and_slide(_velocity, Vector2.UP)
	if is_on_wall():
		_velocity.x *= -1
```

### 重构步骤
1. 创建 `scripts/core/Actor.gd`
2. 修改 `BaseEnemy.gd`：`extends Actor` 替代 `extends CharacterBody2D`
3. 修改 `BaseBoss.gd`：同样
4. 跑测试

---

## 任务 0.2：InputMap 完整（20 分钟）

### 编辑 `project.godot` 的 [input] 段

```ini
[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":68,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":32,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":74,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
dash={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":75,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"physical_keycode":4194325,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":69,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

### 验证
跑项目，按 A/D 移动，W/Space 跳，J 攻击，K dash，E interact，Esc pause

---

## 任务 0.3：PlayerData autoload（30 分钟）

### 文件
- `scripts/core/PlayerData.gd`

### 代码
```gdscript
extends Node
## 全局玩家数据

signal updated
signal died
signal reset

var current_chapter: int = 1
var current_hp: int = 100
var max_hp: int = 100
var current_fp: int = 50
var max_fp: int = 50
var score: int = 0
var deaths: int = 0
var fragments_collected: Array = []  # ["ch1", "ch2", ...]
var playtime_seconds: float = 0.0


func _process(delta: float) -> void:
	playtime_seconds += delta


func add_fragment(fragment_id: String) -> void:
	if fragment_id not in fragments_collected:
		fragments_collected.append(fragment_id)
		emit_signal("updated")


func reset_for_new_game() -> void:
	current_chapter = 1
	current_hp = max_hp
	current_fp = max_fp
	score = 0
	deaths = 0
	fragments_collected = []
	playtime_seconds = 0.0
	emit_signal("reset")
```

### 注册到 project.godot autoload
```ini
[autoload]

PlayerData="*res://scripts/core/PlayerData.gd"
```

---

## 任务 0.4：Portal2D 节点（30 分钟）

### 文件
- `scenes/objects/Portal2D.tscn`
- `scripts/objects/Portal2D.gd`

### Portal2D.tscn 结构
```
Portal2D (Area2D)
├── CollisionShape2D
├── Sprite2D (ColorRect 黄色)
└── AnimationPlayer (fade_out 动画)
```

### Portal2D.gd
```gdscript
extends Area2D
class_name Portal2D

@export var next_scene: PackedScene
@onready var anim: AnimationPlayer = $AnimationPlayer

signal player_entered

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and next_scene:
		player_entered.emit()
		anim.play("fade_out")
		await anim.animation_finished
		get_tree().change_scene_to_packed(next_scene)
```

---

## 任务 0.5：Fragment 收集（20 分钟）

### 文件
- `scenes/objects/Fragment.tscn`
- `scripts/objects/Fragment.gd`

### Fragment.gd
```gdscript
extends Area2D
class_name Fragment

@export var fragment_id: String = "ch1"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		PlayerData.add_fragment(fragment_id)
		queue_free()
```

---

## 任务 0.6：最小可玩关卡（30 分钟）

### 文件
- `scenes/levels/chapter_1/chapter_1_playable.tscn`

### 结构
```
Chapter1 (Node2D)
├── Background (ColorRect)
├── TileMap (Kenney grass tiles)
├── Player (Player.tscn instance)
├── Enemies (Node2D)
│   ├── Knight1
│   └── Knight2
├── Portal2D (出口)
├── Fragment (收集物)
└── HUD (HUD.tscn)
```

### 验证 DoD
- 按 D 走到右侧
- 撞敌人 → 受伤
- 走 3 个平台跳跃
- 收集 Fragment
- 进入 Portal → 切到 chapter_1_boss
- 跑测试 0 回归

---

## 完成检查

- [ ] Actor 基类创建，BaseEnemy/BaseBoss 继承
- [ ] InputMap 完整（移动+跳跃+攻击+闪避+交互+暂停）
- [ ] PlayerData autoload 注册
- [ ] Portal2D 节点可工作
- [ ] Fragment 收集
- [ ] 最小可玩关卡
- [ ] bash tests/run_all_tests.sh 0 失败
- [ ] docs/PHASE_0_DONE.md 写好

**预计**：6 个任务 × 20-30 分钟 = 2-3 小时
**今天目标**：完成 0.1-0.4，明天 0.5-0.6 + Phase 1 启动
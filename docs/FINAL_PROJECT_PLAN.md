# 🗡️ EternalDuty（千年宿命）— 最终项目计划

> **项目代号**: `EternalDuty`
> **类型**: 2D 像素动作 ARPG
> **引擎**: Godot 4.6 + Jolt Physics + Forward+
> **目标平台**: Windows / macOS / Linux / Web
> **计划版本**: v3.0（基于 HeartBeast 模式重构）
> **日期**: 2026-07-18

---

## 🎯 项目愿景

**做出一个看起来像专业的游戏**——不是 1 周 demo，而是 8 周完整作品。

参考：
- **HeartBeast ActionRPG** (C# / 经典教程)
- **awesome-godot** 5 个插件（Maaack / Beehave / XSM / Dialogic / godot-open-rpg）
- **Lango_GodotRPG** (GDScript / Zelda-like)

---

## 📦 故事（继承自 GDD v1.0）

**1267 年的波兰。** 圣剑骑士团守护圣物「千年之心」千年。如今圣物被盗，分成 7 块碎片散落在 7 处禁地。

**你**是被逐出骑士团的无名骑士，回到故土收集 7 块碎片，重新点燃千年之心。

**代价**：每收集一块碎片，你会失去一段记忆。第 7 章前战，主角完全沉默——只剩战斗。

**7 个章节、7 个 Boss、7 块碎片**。

---

## 🏗️ 架构设计（最终版）

### 核心原则（吸收 HeartBeast 模式）

1. **Stats 节点 + 信号**：替代阿迈的 `take_damage()` 函数
2. **HitBox / HurtBox 抽象**：用 Area2D 替代手动距离判断
3. **PlayerDetectionZone**：自动检测玩家
4. **enum 状态机**：< 10 状态用 enum，不用 XSM
5. **Resource 数值化**：.tres 配置文件
6. **Beehave 行为树**：Boss AI
7. **Maaack UI 框架**：菜单
8. **Dialogic**：剧情对话

### 完整目录结构

```
godot-rpg/  (~/Desktop/OpenClaw/godot-rpg/)
├── project.godot
├── README.md
├── .gitignore
├── .github/workflows/ci.yml          # Stage 12
├── docs/                              # 已完成
│   ├── GAME_DESIGN.md                # v1.0
│   ├── DESIGN_RESEARCH.md            # HeartBeast 调研
│   └── FINAL_PROJECT_PLAN.md         # 本文档
├── addons/                           # Stage 0 ✅
│   ├── maaacks_game_template/
│   ├── beehave/
│   ├── xsm/
│   └── dialogic/
├── resources/                        # Stage 1 ✅
│   ├── player/base_player_stats.tres
│   ├── enemies/archer_stats.tres
│   ├── enemies/mage_stats.tres
│   ├── enemies/knight_stats.tres
│   └── bosses/
├── scripts/
│   ├── core/                         # Stage 2 ⏳
│   │   ├── Stats.gd                  # HP + 信号
│   │   ├── HitBox.gd                 # 攻击 Area2D
│   │   ├── HurtBox.gd                # 受击 Area2D
│   │   ├── PlayerDetectionZone.gd    # 玩家检测
│   │   ├── OneShotEffect.gd          # 一次性特效
│   │   └── StateMachine.gd           # enum 状态机基类
│   ├── characters/                   # Stage 3-5 ⏳
│   │   ├── player/
│   │   │   ├── Player.gd
│   │   │   └── SwordHitbox.gd
│   │   ├── enemies/
│   │   │   ├── BaseEnemy.gd
│   │   │   ├── Archer.gd
│   │   │   ├── Mage.gd
│   │   │   └── Knight.gd
│   │   └── bosses/
│   │       ├── BaseBoss.gd
│   │       └── Onyx.gd (最终 boss)
│   ├── systems/                      # Stage 9
│   │   ├── player_stats.gd           # Resource ✅
│   │   ├── enemy_stats.gd            # Resource ✅
│   │   ├── boss_stats.gd             # Resource ✅
│   │   ├── game_state.gd             # 全局游戏状态
│   │   └── save_system.gd            # 存档
│   └── ui/                           # Stage 7
├── scenes/
│   ├── characters/                   # Player + Enemy + Boss 场景
│   ├── levels/
│   │   ├── chapter_1/                # Stage 6
│   │   ├── chapter_2/
│   │   └── ...
│   └── ui/
│       ├── main_menu.tscn
│       ├── pause_menu.tscn
│       └── hud.tscn
├── assets/                           # 像素素材（待收集）
├── audio/                            # 音效 + BGM（待收集）
└── tests/                            # Stage 12
```

---

## 🚀 实施 Stage 拆解（13 个 Stage）

### ✅ Stage 0：项目初始化（已完成）
- 项目目录结构
- 4 个插件安装（Maaack / Beehave / XSM / Dialogic）
- XSM Godot 4 兼容补丁
- app_config 路径修正
- project.godot 配置（5 autoload + 4 editor_plugin + 9 InputMap）

### ✅ Stage 1：数值 Resource 化（已完成）
- `PlayerStats` Resource 类（17 个字段）
- `EnemyStats` Resource 类（18 个字段）
- `BossStats` Resource 类（多阶段）
- 4 个 .tres 配置（base_player / archer / mage / knight）

### ⏳ Stage 2：核心抽象层（最重要）
- `Stats.gd` - 通用 HP 管理 + 信号
- `HitBox.gd` - 攻击 Area2D
- `HurtBox.gd` - 受击 Area2D（自动订阅信号）
- `PlayerDetectionZone.gd` - 玩家检测
- `OneShotEffect.gd` - 一次性特效
- `StateMachine.gd` - enum 状态机基类
- 测试：每个抽象都有 demo 验证

### ⏳ Stage 3：Player 角色
- `Player.gd` - 主控制器（enum 7 状态）
- `SwordHitbox.gd` - 剑攻击 Area2D
- Player.tscn 场景（完整节点树）
- Player 动画（idle/run/jump/attack1-3/dodge/hurt/death）
- 测试：跑游戏能控制玩家移动 + 攻击

### ⏳ Stage 4：敌人基类 + 3 种敌人
- `BaseEnemy.gd` - 通用敌人（enum 4 状态）
- `Archer.gd` - 远程弓箭手
- `Mage.gd` - 法师 + 召唤
- `Knight.gd` - 近战骑士
- 各自场景 + 动画
- 测试：关卡里放 3 种敌人，能正常 AI

### ⏳ Stage 5：1 个 Boss（Chapter 1 的「灰鸦」）
- `BaseBoss.gd` - 通用 Boss（多阶段）
- `Onyx.gd`... 不对，应该是 `Greyr1.gd`（堕落的斥候长）
- Beehave 行为树配置
- 战前 Dialogic 对话
- 战后碎片掉落

### ⏳ Stage 6：1 个完整关卡（Chapter 1）
- `chapter_1_intro.tscn` - 关卡开始
- `chapter_1_combat.tscn` - 主战斗区
- `chapter_1_boss.tscn` - Boss 房
- 关卡连接（传送门/存档点）

### ⏳ Stage 7：UI 框架
- HUD（HP/FP/技能冷却）
- 主菜单（基于 Maaack）
- 暂停菜单（基于 Maaack）
- 选项菜单（音量/分辨率/键位）
- 死亡/胜利界面

### ⏳ Stage 8：剧情对话（Dialogic）
- Chapter 1 战前对话（引子）
- Chapter 1 战后对话（碎片收集）
- 7 章节共 14 段对话
- 记忆碎片画面（每章节后）

### ⏳ Stage 9：存档系统
- 3 个手动存档位 + 1 个自动
- 存档数据结构（HP/位置/碎片/技能）
- 死亡复活 + 读取存档
- 多存档位 UI

### ⏳ Stage 10：其余 Boss + 关卡（6 个）
- 6 个 Boss 复用 BaseBoss + Beehave
- 6 个章节地图

### ⏳ Stage 11：视觉特效 + 音效
- 粒子系统（攻击/受击/技能）
- 屏幕震动
- 伤害飘字
- BGM + SFX 集成

### ⏳ Stage 12：测试 + CI
- gdUnit4 测试覆盖（核心逻辑）
- GitHub Actions CI
- 静态检查脚本

### ⏳ Stage 13：打磨 + 发布
- README + CHANGELOG
- 截图
- GitHub 发布（推到 wyzhou01 账号）
- 本地副本（godot-platformer-test 风格）

---

## 🎮 核心脚本代码骨架（Stage 2-5）

### Stats.gd（最关键的抽象）

```gdscript
class_name Stats extends Node
## 通用 HP 管理节点 + 信号机制（替代 take_damage()）

signal health_decreased_and_depleted  # HP 归零
signal health_decreased_but_not_depleted  # 受击但没死
signal health_increased

@export var max_health: int = 100
var health: int : set = _set_health

func _ready():
    health = max_health

func _set_health(value):
    var prev = health
    health = clamp(value, 0, max_health)
    if health < prev:
        if health <= 0:
            health_decreased_and_depleted.emit()
        else:
            health_decreased_but_not_depleted.emit()
    elif health > prev:
        health_increased.emit()
```

### HitBox.gd

```gdscript
class_name HitBox extends Area2D
## 攻击者挂的 Area2D
@export var damage: int = 10
@export var knockback_force: float = 200.0
@export var direction: Vector2 = Vector2.RIGHT

func _ready():
    # 默认 layer=4 (玩家攻击), mask=4 (敌人受击)
    collision_layer = 4
    collision_mask = 4
```

### HurtBox.gd（自动订阅）

```gdscript
class_name HurtBox extends Area2D
## 受击者挂的 Area2D（自动检测 HitBox 进入）

func _ready():
    area_entered.connect(_on_area_entered)
    collision_layer = 2
    collision_mask = 4  # 检测 HitBox

func _on_area_entered(area: Area2D):
    if area is HitBox:
        var stats = get_parent().get_node_or_null("Stats")
        if stats and stats.has_method("take_damage"):
            stats.take_damage(area.damage)
```

### BaseEnemy.gd（HeartBeast 模式）

```gdscript
class_name BaseEnemy extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT }
var state: State = State.IDLE

@onready var stats: Stats = $Stats
@onready var hurt_box: HurtBox = $HurtBox
@onready var detection: PlayerDetectionZone = $PlayerDetectionZone
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var enemy_stats: EnemyStats

var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready():
    add_to_group("enemy")
    stats.max_health = enemy_stats.max_hp
    stats.health = enemy_stats.max_hp
    stats.health_decreased_but_not_depleted.connect(_on_hurt)
    stats.health_decreased_and_depleted.connect(_on_death)
    if detection:
        detection.player_detected.connect(_on_player_detected)

func _physics_process(delta):
    match state:
        State.IDLE: _process_idle(delta)
        State.CHASE: _process_chase(delta)
        State.ATTACK: _process_attack(delta)
        State.HURT: pass
    move_and_slide()
```

### Player.gd（enum 状态机）

```gdscript
class_name Player extends CharacterBody2D

enum State { IDLE, RUN, JUMP, ATTACK, DODGE, HURT, DEATH }
var state: State = State.IDLE

@export var player_stats: PlayerStats
@onready var stats: Stats = $Stats
@onready var hitbox_pivot: Node2D = $HitboxPivot
@onready var sword_hitbox: HitBox = $HitboxPivot/SwordHitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
    match state:
        State.IDLE: _process_idle(delta)
        State.RUN: _process_run(delta)
        State.JUMP: _process_jump(delta)
        # ...
    move_and_slide()
```

---

## 📊 时间表

| 阶段 | 内容 | 估算 |
|------|------|------|
| ✅ Stage 0-1 | 基础设施 + Resource | 已完成 |
| ⏳ Stage 2 | 核心抽象（Stats/HitBox/HurtBox/etc） | 1 天 |
| ⏳ Stage 3 | Player + 动画 | 1-2 天 |
| ⏳ Stage 4 | 敌人 + 3 种 | 1-2 天 |
| ⏳ Stage 5 | 1 个 Boss | 1 天 |
| ⏳ Stage 6 | Chapter 1 关卡 | 1 天 |
| ⏳ Stage 7 | UI 框架 | 1 天 |
| ⏳ Stage 8 | Dialogic 对话 | 1 天 |
| ⏳ Stage 9 | 存档 | 0.5 天 |
| ⏳ Stage 10 | 其余 Boss/关卡 | 5-7 天 |
| ⏳ Stage 11 | 特效 + 音游 | 2-3 天 |
| ⏳ Stage 12 | 测试 + CI | 1 天 |
| ⏳ Stage 13 | 打磨 + 发布 | 1 天 |
| **总计** | | **15-22 天** |

**MVP（Stage 0-7）**：5-7 天，能玩到完整 Chapter 1
**完整（Stage 0-13）**：15-22 天

---

## 🎯 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 玩家状态机 | enum + switch | < 10 状态用 enum 够用 |
| Boss AI | Beehave 行为树 | 多阶段 + 多技能 |
| HP 管理 | Stats 节点 + 信号 | HeartBeast 模式，最优雅 |
| 数值配置 | Resource .tres | 数据驱动 |
| 攻击判定 | Area2D HitBox | 精确形状 |
| 玩家检测 | PlayerDetectionZone | 自动检测 |
| UI 框架 | Maaack 模板 | 开箱即用 |
| 对话系统 | Dialogic | 可视化编辑器 |
| 存档 | Resource + ResourceSaver | Godot 原生 |
| 资源 | 阿迈原版素材 + 网上找免费的 | 不重复造轮子 |

---

## 📝 GitHub 仓库

- **本地**: `~/Desktop/OpenClaw/godot-rpg/`
- **GitHub**: 推到 wyzhou01 账号（创建新 repo）
- **本地副本**: `~/Desktop/OpenClaw/godot-rpg-test/`（无 .git）

---

## 🚦 下一步

立即执行：
1. ✅ Stage 2：核心抽象层（Stats / HitBox / HurtBox / PlayerDetectionZone / OneShotEffect / StateMachine）
2. ✅ Stage 3：Player 角色（enum 状态机）
3. ✅ Stage 4：敌人基类 + Archer
4. ✅ Stage 5：1 个 Boss demo（"灰鸦"）
5. ⏳ Stage 6+：继续推进

**执行原则**：
- 不轻易妥协
- 遇问题搜解决方案
- 不断测试验证
- 不让阿迈干预

---

*生成时间: 2026-07-18*
*执行者: 嘟嘟 (MiniMax-M3)*
*基于: HeartBeast ActionRPG + awesome-godot + Lango_GodotRPG*
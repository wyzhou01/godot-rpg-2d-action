# 🔍 设计调研报告 — 基于参考项目

> **调研时间**: 2026-07-18
> **目的**: 在写 GDD v2.0 和开始写代码前，先看成熟的参考项目
> **方法**: web 搜索 + clone 关键项目深读代码

---

## 📚 参考项目

### 1. HeartBeast ActionRPG（核心参考）

- **仓库**: https://github.com/devklick/HeartBeast-ActionRPG
- **作者**: HeartBeast（YouTube 教程系列作者）
- **来源**: 阿迈 game-2.0 实际上就是基于这个教程系列的（看代码风格可确认）
- **引擎**: Godot 4 + C#
- **结构**: `Player / Enemies / Generic / Overlap / UI / World / Effects / Shadows / Music and Sounds`

#### 🎯 关键设计模式（要吸收的）

##### 模式 1: `Stats` 节点 + 信号机制（替代 `take_damage()`）

**阿迈原版的问题**：
```gdscript
# player.gd
func take_damage(_amount: int = 1) -> void:
    if is_dead or is_invincible: return
    die()  # 直接调用死亡方法

# enemy.gd
func take_damage(amount: int) -> void:
    if is_dead: return
    health -= amount
    if health <= 0:
        die()
```

每个敌人都自己实现 `take_damage`，有 `is_dead / is_invincible` 标志，代码重复。

**HeartBeast 的方案**：
```csharp
// Stats.cs - 一个独立的 Node 挂在角色上
public class Stats : Node {
    [Export] public readonly int MaxHealth = 1;
    [Export] public int Health { get => health; set => SetHealth(value); }
    
    [Signal] public delegate void HealthDecreasedAndDepleted();
    [Signal] public delegate void HealthDecreasedButNotDepleted();
    
    private void SetHealth(int value) {
        if (value < health) {
            if (value <= 0) EmitSignal(HealthDecreasedAndDepleted);
            else EmitSignal(HealthDecreasedButNotDepleted);
        }
        health = value;
    }
}
```

敌人订阅这两个信号，自动响应：
```csharp
// Bat.cs
stats.Connect(Stats.HealthDecreasedAndDepletedSignalName, this, nameof(_on_Stats_HealthDecreasedAndDepleted));
stats.Connect(Stats.HealthDecreasedButNotDepletedSignalName, this, nameof(_on_Stats_HealthDecreasedButNotDepleted));

private void _on_Stats_HealthDecreasedAndDepleted() {
    var effect = _enemyDestroyedScene.Instance<OneShotEffect>();
    GetParent().AddChild(effect);
    effect.GlobalPosition = GlobalPosition;
    QueueFree();
}
```

**优势**：
- 攻击者和受击者**完全解耦**（不互相 know about）
- 多个订阅者可以响应同一种事件（受伤音效 + 受伤特效 + UI 飘字 都能各自订阅）
- 新增"受伤类型"（中毒/燃烧/冻伤）只需新增信号，不改调用方

##### 模式 2: HitBox / HurtBox 抽象

```
Player 节点树:
├── Player (CharacterBody2D)
│   ├── HitboxPivot (Node2D, 旋转决定攻击方向)
│   │   └── SwordHitbox (Area2D, 继承 HitBox)
│   │       └── CollisionShape2D
│   ├── HurtBox (Area2D)
│   └── Stats (Node)
```

- **HitBox**：攻击者挂的碰撞范围。攻击时启用，结束禁用（Animation track 控制）
- **HurtBox**：受击者挂的碰撞范围。一直启用。
- 通过 `collision_layer` / `collision_mask` 配对：HitBox layer=4，HurtBox mask=4，互相检测。

**好处**：
- 不用手算 80px 攻击范围（Area2D 形状精确）
- 一个 HitBox 可以被多个 HurtBox 同时触发（横扫一片敌人都掉血）
- 攻击方向切换 = 旋转 `HitboxPivot` 而不是改代码

##### 模式 3: PlayerDetectionZone

```csharp
public class PlayerDetectionZone : Area2D {
    public Player.Player Player;
    
    public override void _Ready() {
        Connect("body_entered", this, nameof(_on_body_entered));
        Connect("body_exited", this, nameof(_on_body_exited));
    }
    
    public bool PlayerDetected => Player != null;
}
```

敌人挂这个 Area2D，自动检测玩家进出范围。比阿迈原版的 `get_tree().get_first_node_in_group("player")` 优雅。

##### 模式 4: enum 状态机（4-5 状态足够）

```csharp
public enum PlayerState { Idle, Run, Attack, Roll }
public enum BatStat { Idle, Wander, Chase }
```

**关键洞察**：4-5 状态用 enum 够了，XSM overkill。**只有 10+ 状态才需要 XSM**。

阿迈的 player 有 5 个状态（idle/run/jump/attack/dodge/die），其实 enum + switch 更简洁。

##### 模式 5: Animation 控制碰撞启用

```
Attack Animation Track:
0.0s: HitboxPivot.rotation_degrees = 90 (朝下)
0.1s: SwordHitbox/CollisionShape2D.disabled = false (启用攻击)
0.3s: SwordHitbox/CollisionShape2D.disabled = true (结束攻击)
0.4s: method = "MoveToIdleState" (回到 idle)
```

**关键**：攻击窗口 = 0.1s 到 0.3s。Animation 帧精度，不是代码计时。

---

### 2. Lango_GodotRPG（结构参考）

- **仓库**: https://github.com/Delta12Studio/Lango_GodotRPG
- **类型**: Zelda-like RPG
- **结构**: `Effects / Enemies / Font / Hitboxes and Hurtboxes / Levels / Music and Sounds / NPC / Player / Shadows / Translation / UI / World`
- **特色**:
  - **Hitboxes and Hurtboxes 独立目录**（和组织 HitBox / HurtBox 抽象）
  - **NPC 独立目录**（支持对话/任务）
  - **Translation 目录**（i18n）
  - **Effects 目录**（粒子/特效）

---

### 3. Kenney 免费资源（资产）

- **网站**: https://www.kenney.nl/
- **类型**: 数千个免费游戏资源（CC0 协议）
- **重点**: 2D Platformer Bundle（含角色/TileSet/UI/SFX/BGM 一整套）

---

## 🎮 EternalDuty 项目最终架构

吸收 HeartBeast 模式 + awesome-godot 插件，得出：

### 玩家架构

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HitboxPivot (Node2D, 根据方向旋转)
│   └── SwordHitbox (Area2D, HitBox 子类)
│       └── CollisionShape2D
├── HurtBox (Area2D)
├── PlayerStats (Node, Stats 模式)
├── AnimationPlayer (控制动画+碰撞启用+攻击窗口)
└── StateMachine (enum-based, 6 个状态)
    ├── Idle
    ├── Run
    ├── Jump
    ├── Attack (3 段)
    ├── Dodge
    ├── Hurt
    └── Death
```

### 敌人架构

```
Enemy (CharacterBody2D, base_enemy.gd)
├── AnimatedSprite2D
├── CollisionShape2D
├── HurtBox (Area2D)
├── PlayerDetectionZone (Area2D)
├── EnemyStats (Node, Stats 模式 + Resource 配置)
├── AnimationPlayer
├── StateMachine (enum-based)
│   ├── Idle (玩家不在范围)
│   ├── Chase (玩家进入范围)
│   ├── Attack (在攻击范围)
│   └── Hurt (受击动画)
└── Optional: BehaviorTree (Beehave) for 复杂 AI
```

### Boss 架构

```
Boss (CharacterBody2D, base_boss.gd)
├── AnimatedSprite2D
├── CollisionShape2D
├── HurtBox (Area2D)
├── PlayerDetectionZone (Area2D)
├── BossStats (Node, 多阶段 HP 阈值)
├── AnimationPlayer
├── BehaviorTree (Beehave, 复杂 AI)
│   ├── Phase Selector (根据 HP 选技能)
│   ├── Sequence: Death (< 0 HP)
│   └── Various Action nodes
├── ProjectileSpawner (多个子弹类型)
└── DialogueTrigger (战前/战后对话)
```

### 通用脚本架构

```
scripts/
├── core/
│   ├── Stats.gd                # 通用 HP 管理 + 信号
│   ├── HitBox.gd               # 攻击碰撞 Area2D
│   ├── HurtBox.gd              # 受击碰撞 Area2D
│   ├── PlayerDetectionZone.gd  # 玩家检测 Area2D
│   ├── OneShotEffect.gd        # 一次性特效
│   └── StateMachine.gd         # enum-based 状态机
├── characters/
│   ├── player/
│   │   ├── Player.gd
│   │   └── SwordHitbox.gd
│   ├── enemies/
│   │   ├── BaseEnemy.gd
│   │   ├── Archer.gd
│   │   ├── Mage.gd
│   │   └── Knight.gd
│   └── bosses/
│       ├── BaseBoss.gd
│       └── bosses/
├── systems/
│   ├── PlayerStats.gd (Resource 配置)
│   ├── EnemyStats.gd
│   ├── BossStats.gd
│   ├── GameState.gd
│   └── SaveSystem.gd
└── ui/
    ├── HUD.gd
    └── DamageNumber.gd
```

---

## 📊 关键技术决策

### 决策 1: 状态机选 enum 还是 XSM？

| 状态数 | 推荐 |
|--------|------|
| < 6 | enum + switch（HeartBeast 模式） |
| 6-10 | enum + state class 字典 |
| 10+ | XSM（场景树节点） |
| 并行/嵌套 | XSM（hierarchical） |

**EternalDuty 选择**：
- Player：7 个状态（Idle/Run/Jump/Attack/Dodge/Hurt/Death），用 **enum + state class 字典**（吸收 HeartBeast 模式 + 简单性）
- Boss：复杂多阶段，用 **Beehave 行为树**（XSM 不必要）

### 决策 2: 数值配置用什么？

| 方式 | 适用 |
|------|------|
| Hardcoded | 简单 demo |
| `@export` 变量 | Inspector 调试 |
| `Resource` 类 + `.tres` | **多场景复用 + 数据驱动** ✅ |

**EternalDuty 选择**：用 Resource + .tres，每个敌人/boss 都从 .tres 读数值。

### 决策 3: HP 管理用什么？

| 方式 | 问题 |
|------|------|
| `take_damage()` 函数 | 调用方要知道受击者是谁，耦合 |
| bool `is_dead` 标志 | 重复代码，订阅难 |
| **`Stats` 节点 + 信号** | 解耦，多订阅者 ✅ |

**EternalDuty 选择**：Stats 节点 + 信号（HeartBeast 模式）。

### 决策 4: AI 行为用什么？

| 方式 | 适用 |
|------|------|
| if/else + 标志位 | 简单敌人（1-2 行为） |
| enum 状态机 | 中等（4-6 行为） |
| **Beehave 行为树** | **Boss + 复杂敌人** ✅ |
| FSM 节点（XSM） | UI 状态、角色状态 |

**EternalDuty 选择**：
- 普通敌人：enum 状态机
- Boss：Beehave 行为树（多阶段 + 多技能组合）

---

## 🎯 给 EternalDuty 的关键改进（对比阿迈原版）

| 阿迈原版 | EternalDuty |
|---------|-------------|
| `is_dead / is_invincible / is_attacking` 标志 | Stats 节点 + 信号 |
| `take_damage(amount)` 函数调用 | `_on_HurtBox_area_entered` 信号订阅 |
| 80px 圆形攻击范围（手动距离判断） | HitBox Area2D（精确形状） |
| 每帧 `get_tree().get_first_node_in_group("player")` | PlayerDetectionZone Area2D |
| 6 个 boss 各写各的 `take_damage / die` | `BaseBoss.gd` 抽象 + Beehave AI |
| 攻击范围手动启用/禁用 | Animation track 控制 |
| bool `is_acting / is_dodging` 标志 | enum 状态机 + AnimationPlayer 信号 |

---

## 📝 下一步

1. ✅ 重写 GDD v2.0 吸收这些模式（已完成）
2. ⏳ 改写已存在的代码：
   - 重写 `player.gd` 用 Stats 节点 + enum 状态机
   - 重写 `base_enemy.gd` 用 Stats 节点 + PlayerDetectionZone
3. ⏳ 写 `BaseBoss.gd` 用 Beehave 行为树
4. ⏳ 写 HitBox / HurtBox 抽象

---

*生成时间: 2026-07-18*
*执行者: 嘟嘟 (MiniMax-M3)*
*参考: HeartBeast ActionRPG + Lango_GodotRPG + awesome-godot*
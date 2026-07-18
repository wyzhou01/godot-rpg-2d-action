# 🛠️ EternalDuty — Godot 场景配置指南

> **当前状态**: 所有 .gd 脚本已完成（约 1440 行），但 .tscn 场景需要在 Godot 编辑器里手动创建
> **本指南**: 详细步骤教你创建所有场景，配置好后即可跑游戏

---

## 📋 前置条件

- ✅ Godot 4.6+ 已安装
- ✅ 4 个插件已装到 `addons/`（Maaack / Beehave / XSM / Dialogic）
- ✅ 所有 .gd 脚本已写好（`scripts/` 目录下）
- ✅ 所有 Resource 已配置（`resources/` 目录下）

---

## 🚀 启动项目

```bash
cd ~/Desktop/OpenClaw/godot-rpg
godot project.godot
```

第一次启动会：
1. 扫描所有脚本（生成 .uid 文件）
2. 加载 4 个插件
3. 注册 5 个 autoload

**如果报错**，看下面"常见问题"章节。

---

## 1️⃣ 创建 Player 场景

### 节点结构

```
Player (CharacterBody2D, 挂 Player.gd)
├── AnimatedSprite2D
├── CollisionShape2D
├── Stats (Node, 挂 Stats.gd)
├── HurtBox (Area2D, 挂 HurtBox.gd)
│   └── CollisionShape2D
├── HitboxPivot (Node2D)
│   └── SwordHitbox (Area2D, 挂 SwordHitbox.gd)
│       └── CollisionShape2D
├── StateMachine (Node, 挂 StateMachine.gd)
└── AnimationPlayer
```

### 步骤

1. **新建场景**: Scene → New Scene
2. **根节点**: Other Node → CharacterBody2D，重命名为 `Player`
3. **挂脚本**: Inspector → Script → `res://scripts/characters/player/Player.gd`
4. **配置 Player Stats**: Inspector → Player Stats → Load → `res://resources/player/base_player_stats.tres`
5. **添加子节点**:
   - `AnimatedSprite2D`（用于显示精灵）
   - `CollisionShape2D`（设置 Shape 为 RectangleShape2D, size=(20,40)）
   - `Stats` (Node, 挂 `Stats.gd`)
   - `HurtBox` (Area2D, 挂 `HurtBox.gd`)
     - 添加 `CollisionShape2D`
   - `HitboxPivot` (Node2D)
     - 子节点：`SwordHitbox` (Area2D, 挂 `SwordHitbox.gd`)
       - 添加 `CollisionShape2D`，Shape 设为 RectangleShape2D, size=(50,30)
   - `StateMachine` (Node, 挂 `StateMachine.gd`)
   - `AnimationPlayer`

### 配置 Collision Layers

- `Player` 自身: layer=1, mask=1（地面）
- `HurtBox`: layer=2 (PLAYER_HURTBOX), mask=4 (检测玩家攻击——不，自己人不能打自己)
  - 实际：`collision_layer = 2`, `collision_mask = 0`（只是被敌人检测）
- `SwordHitbox`: `collision_layer = 4`, `collision_mask = 4`

### 创建 AnimationPlayer 动画

需要创建以下动画（AnimationPlayer 节点下）：

| 动画名 | 长度 | 关键帧 |
|--------|------|--------|
| `idle` | 0.6 | Sprite frame 循环 |
| `run` | 0.5 | Sprite frame 循环 |
| `jump` | 0.3 | 单帧 |
| `fall` | 0.3 | 单帧 |
| `attack_1` | 0.3 | 3 帧 + 启用 SwordHitbox (方法 track: `_enable_attack_hitbox()`) + 禁用 (0.3s) |
| `attack_2` | 0.3 | 同上 |
| `attack_3` | 0.5 | 同上 + 禁用 |
| `dodge` | 0.25 | 单帧 |
| `hurt` | 0.3 | 单帧 |
| `death` | 0.6 | 单帧 |

**关键**: 在 attack_1 / attack_2 / attack_3 的 Method Track 里调用：
- `_enable_attack_hitbox()` 在第 2 帧
- on_animation_finished 自动重置

### 保存

File → Save As → `res://scenes/characters/player/player.tscn`

### 测试

按 F5 (Play) 看是否能控制：
- A/D 移动
- Space 跳跃
- 鼠标左键 攻击
- Shift 闪避

---

## 2️⃣ 创建 Archer / Mage / Knight 敌人场景

### 通用节点结构（BaseEnemy）

```
Enemy (CharacterBody2D, 挂 BaseEnemy.gd 或子类)
├── AnimatedSprite2D
├── CollisionShape2D
├── Stats (Node, 挂 Stats.gd)
├── HurtBox (Area2D, 挂 HurtBox.gd)
│   └── CollisionShape2D
├── PlayerDetectionZone (Area2D, 挂 PlayerDetectionZone.gd)
│   └── CollisionShape2D (size: 800x600)
├── AnimationPlayer
└── (Archer/Mage only) ProjectileSpawner (Node2D)
```

### Archer 步骤

1. New Scene → CharacterBody2D, 重命名 `Archer`
2. Script: `res://scripts/characters/enemies/Archer.gd`
3. Inspector → Enemy Stats → Load → `res://resources/enemies/archer_stats.tres`
4. 添加子节点（同上）
5. 添加 `ProjectileSpawner` (Node2D)
6. 创建 Arrow 场景（见下）
7. 设置 Archer 的 Projectile Scene（Inspector）→ `res://scenes/characters/projectiles/arrow.tscn`

### 创建 Arrow 场景（Archer 用）

```
Arrow (Area2D, 挂 Arrow.gd)
├── Sprite2D
└── CollisionShape2D (RectangleShape2D, size=10x5)
```

Arrow.gd 脚本（自己写，简单直线飞行 + HitBox 逻辑）：
```gdscript
extends Area2D
class_name Arrow

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var attacker: Node = null
var damage: int = 1
var lifetime: float = 3.0

func initialize(dir: Vector2, spd: float) -> void:
    direction = dir
    speed = spd
    rotation = direction.angle()
    collision_layer = 8  # ENEMY_ATTACK
    collision_mask = 4   # 检测玩家 HurtBox

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    lifetime -= delta
    if lifetime <= 0:
        queue_free()

func _on_area_entered(area: Area2D) -> void:
    if area is HurtBox:
        var stats = area.stats
        if stats:
            stats.take_damage(damage)
        queue_free()
```

### 类似创建 Mage 和 Knight

- **Mage**: 用 `mage_stats.tres`，需要 MagicProjectile 场景（类似 Arrow 但可以斜飞）
- **Knight**: 用 `knight_stats.tres`，无 Projectile

---

## 3️⃣ 创建 Greyr1 Boss 场景（Chapter 1）

### 节点结构

```
Greyr1 (CharacterBody2D, 挂 Greyr1.gd)
├── AnimatedSprite2D
├── CollisionShape2D
├── Stats (Node, 挂 Stats.gd)
├── HurtBox (Area2D, 挂 HurtBox.gd)
│   └── CollisionShape2D
├── PlayerDetectionZone (Area2D, 挂 PlayerDetectionZone.gd)
├── AnimationPlayer
├── BeehaveTree (Node, 挂 Beehave 插件)
└── ProjectileSpawner (Node2D)
```

### 步骤

1. New Scene → CharacterBody2D, 重命名 `Greyr1`
2. Script: `res://scripts/characters/bosses/Greyr1.gd`
3. Inspector → Boss Stats → Load → `boss_stats.tres`（手动创建）
4. 配置 BeehaveTree（详见 Beehave 文档）

### 创建 boss_stats.tres

1. FileSystem → 右键 `resources/bosses/` → New Resource
2. Type: BossStats
3. 配置: HP=200, attack_power=15, chapter=1, ...

---

## 4️⃣ 创建 Chapter 1 关卡

### 节点结构

```
Chapter1 (Node2D)
├── TileMap (背景瓦片)
├── Player (instance)
├── Enemies (Node2D)
│   ├── Archer (instance)
│   ├── Mage (instance)
│   └── Knight (instance)
├── BossSpawn (Marker2D)
├── Checkpoint (Area2D)
└── ExitTrigger (Area2D)
```

### 步骤

1. New Scene → Node2D, 重命名 `Chapter1`
2. 实例化 Player 场景
3. 实例化多个 Archer / Mage / Knight
4. 添加 TileMap（需要先准备瓦片资源）
5. 添加 BossSpawn（Marker2D），位置定在关卡末尾
6. 设置 Player 的初始位置

---

## 5️⃣ 创建 UI 场景

### HUD 场景

```
HUD (CanvasLayer)
├── HPBar (ProgressBar)
├── FPBar (ProgressBar)
├── SkillIcons (HBoxContainer)
│   ├── AttackIcon
│   ├── DodgeIcon
│   ├── WarCryIcon
│   └── HealIcon
└── DamageNumberLayer (Node2D)
```

### 主菜单

参考 Maaack 模板的示例：
- `addons/maaacks_game_template/examples/scenes/menus/main_menu/main_menu.tscn`

---

## 6️⃣ 配置 Dialogic 对话

### 创建第一个对话

1. FileSystem → 右键 `dialogs/` → New → Dialogic → Timeline
2. 命名: `greyr1_intro.dlg`
3. 在 Dialogic 编辑器添加事件:
   - **Text**: "你终于来了，骑士。"
   - **Character**: 选择/创建角色"灰鸦"
   - **Text**: "千年之心已经破碎，你还要追寻吗？"
   - **Choice**: "我会集齐碎片" / "放下执念"（分支）
   - **End**

### 触发对话

```gdscript
# 在 Greyr1 的触发器节点里
extends Area2D

func _on_body_entered(body):
    if body.is_in_group("player"):
        Dialogic.start("res://dialogs/greyr1_intro.dlg")
        await Dialogic.timeline_ended
        get_parent().start_boss_fight()
```

---

## 7️⃣ 测试运行

按 F5 (Play Scene Current Scene) 或 F6 (Play Custom Scene)

### 期望结果
- ✅ 玩家在场景中出生
- ✅ 敌人检测到玩家后开始行动
- ✅ 玩家攻击敌人（HitBox 碰撞）→ 敌人 HP 减少
- ✅ 敌人攻击玩家 → 玩家 HP 减少
- ✅ Boss 触发战前对话
- ✅ Boss HP < 33% 时进入狂暴阶段

---

## 🐛 常见问题

### Q: 报错 `Invalid call. Nonexistent function 'take_damage'`
**A**: 父节点没有 Stats 子节点。检查 Player.tscn 的子节点树，确保有 Stats。

### Q: HitBox 不触发
**A**: 检查 Collision Layers：
- SwordHitbox: layer=4, mask=4
- Enemy HurtBox: layer=2, mask=4

### Q: Beehave 树不工作
**A**: Beehave 插件可能没启用。Project Settings → Plugins → 勾选 Beehave。

### Q: Dialogic 报 path 错
**A**: Dialogic 自动注册 autoload。如果没生效，删除 `.godot/global_script_class_cache.cfg` 重启 Godot。

---

## 🎮 接下来

配置完成后，你应该能玩到：
1. Player 控制（移动/攻击/闪避）
2. 3 种敌人（弓箭手/法师/骑士）
3. 1 个 Boss「灰鸦」（3 阶段）
4. Chapter 1 关卡（最简版）

后续 stage：
- Stage 6-9：UI / 对话 / 存档
- Stage 10：其余 6 个 Boss + 关卡
- Stage 11：特效 + 音效
- Stage 12-13：测试 + 发布

---

*生成时间: 2026-07-18*
*适用于 Godot 4.6+*
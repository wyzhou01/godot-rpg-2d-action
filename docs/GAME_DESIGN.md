# 🗡️ 「千年宿命」— 游戏设计文档 (GDD)

> **代码名**: `EternalDuty` (千年宿命)
> **类型**: 2D 像素动作 ARPG / 平台跳跃
> **引擎**: Godot 4.6 + Jolt Physics + Forward+
> **目标平台**: Windows / macOS / Linux / Web (HTML5)
> **文档版本**: v1.0
> **日期**: 2026-07-18

---

## 📖 故事 (Story)

### 主线

> **1267 年的波兰。**
> 圣剑骑士团守护圣物「千年之心」千年。如今，圣物被盗，国王驾崩，王国陷入混沌。
>
> **你**是一名无名骑士——曾是圣剑骑士团的一员。三年前因为拒绝参与王室内斗被逐出骑士团，流亡荒野。
>
> 三年后，王国的最后一道火焰——「黎明之钟」即将熄灭。你回到这片故土，发现：
> - 旧日的战友都已战死或堕落
> - 圣物「千年之心」被分成了 7 块碎片，散落在王国的 7 处禁地
> - 唯一知道碎片下落的人，是你的宿敌——当年的骑士团团长「黑曜」（The Onyx），他已化身最终boss
>
> **你的任务**：穿越 7 处禁地，集齐 7 块碎片，重新点燃「千年之心」，终结这场宿命。
>
> **但你必须付出代价**：每收集一块碎片，你会失去一段记忆。当 7 块碎片集齐时，你也会忘记自己为什么出发——就像 3000 年前的初代守护者一样。

### 主题

- **宿命与传承**（你重走前人之路）
- **记忆与遗忘**（每个碎片让你忘记一段过去）
- **牺牲与救赎**（最终你也要成为下个守护者）

### 章节结构（7 章 + 7 boss）

| 章 | 名称 | 主题色 | boss |
|----|------|--------|------|
| 1 | 荒原 | 灰 | 堕落的斥候长「灰鸦」 |
| 2 | 边陲古堡 | 蓝 | 叛教法师「寒霜」 |
| 3 | 地下墓穴 | 紫 | 死灵领主「腐骨」 |
| 4 | 失落圣殿 | 金 | 圣殿骑士长「金卫」 |
| 5 | 火焰山脉 | 红 | 火焰巨龙「炎心」 |
| 6 | 幻影森林 | 绿 | 暗影德鲁伊「翠语」 |
| 7 | 王座大厅 | 黑 | 宿敌「黑曜」（最终 boss + 二阶段：3000 年前的初代守护者幻影） |

---

## 🎮 核心玩法 (Core Gameplay)

### 操作

| 按键 | 动作 |
|------|------|
| `A` / `D` | 左右移动 |
| `Space` | 跳跃（可二段跳） |
| `Shift` | 冲刺（带无敌帧 0.2s） |
| `鼠标左键` | 剑攻击（3 段连击） |
| `鼠标右键` | 盾反（成功时敌方眩晕 1s） |
| `Q` | 战吼（击退 + 短暂无敌 0.5s，冷却 8s） |
| `E` | 治疗（消耗专注值，回复 30% HP） |
| `R` | 终极技能（每章 1 次，碎片解锁后获得） |
| `Esc` | 暂停菜单 |

### 属性

| 属性 | 初始 | 升级 | 说明 |
|------|------|------|------|
| HP（血量） | 100 | 碎片+ | 受击扣减 |
| FP（专注值） | 50 | 碎片+ | 治疗/战吼消耗 |
| 攻击力 | 10 | 碎片+ | 剑伤害基础值 |
| 防御力 | 5 | 碎片+ | 减伤百分比 |
| 移动速度 | 220 px/s | — | — |
| 跳跃力 | -480 | — | — |
| 冲刺冷却 | 1s | — | 冷却时间 |

### 战斗系统

#### 剑攻击（3 段连击）

```
第 1 段: 横扫（前 90°，伤害 10，前摇 8 帧）
   ↓ 0.15s 内可接
第 2 段: 上挑（前 60°，伤害 12，前摇 10 帧，可击飞轻甲敌人）
   ↓ 0.15s 内可接
第 3 段: 下劈（前 90°，伤害 18，前摇 14 帧，地面冲击波）
```

#### 盾反（关键技能）

- 按右键举起盾牌
- 敌人攻击命中盾牌的瞬间按攻击键 → 盾反成功
- 成功：敌方眩晕 1s + 你回复 5 FP
- 失败：HP 减少 + 短暂硬直

#### 战吼

- 半径 100px 圆形 AOE
- 击退所有敌人 + 自己 0.5s 无敌
- 消耗 15 FP，冷却 8s

#### 治疗

- 立即回复 30% 最大 HP
- 消耗 20 FP
- 战斗中受击会中断

### 敌人系统

#### 普通敌人（每章 3-4 种）

| 类型 | 章 | HP | 行为 |
|------|----|----|------|
| 弓箭手 | 1-7 | 8 | 远程，原地射箭（参考阿迈原版） |
| 法师 | 2-7 | 6 | 魔法弹 + 召唤骷髅 |
| 近战骑士 | 1-7 | 12 | 直线追踪 + 80px 攻击范围 |
| 骷髅 | 3 | 4 | 群体围攻 |
| 重装步兵 | 4-7 | 25 | 缓慢冲锋，霸体 |
| 飞行蝙蝠 | 3-5 | 6 | 飞行轨迹 + 俯冲 |
| 自爆蜘蛛 | 6-7 | 3 | 接近后自爆 AOE |

#### 精英敌人（每章 1-2 种）

HP 普通版本的 2-3 倍，有特殊技能

#### Boss（7 个）

每个 boss:
- **3 个阶段**（100% → 66% → 33% HP）
- 每阶段 2-3 个技能 + 1 个狂暴机制
- 战前有剧情对话（Dialogic）
- 战后有剧情 + 1 块碎片 + 1 个新技能解锁

### 进度系统

#### 碎片收集

- 7 章 7 块碎片
- 每块碎片:
  - 永久属性加成（HP+10 / 攻击+2 / 防御+1）
  - 解锁新技能
  - 显示主角的"记忆碎片"画面（30s 短动画）

#### 记忆系统（剧情特色）

- 收集碎片后，主角的对话框文字逐渐变短（暗示失去语言能力）
- 第 4 章后，对话只有单词
- 第 7 章前战，主角完全沉默
- 最终 boss 战后，主角说出了唯一的完整句子（呼应开场）

#### 多存档位

- 3 个手动存档位 + 1 个自动存档位
- 每个存档保存：当前位置、HP/FP、已收集碎片、技能、敌人击杀数

---

## 🏗️ 技术架构

### 引擎配置

```
Godot 4.6 + Jolt Physics + Forward+
渲染：Forward+（保留原项目配置）
物理：Jolt Physics 3D（Godot 4.3+）
输入：InputMap（A/D/Space/Shift/Mouse/Q/E/R/Esc）
```

### 插件清单

| 插件 | 版本 | 用途 | 学习价值 |
|------|------|------|---------|
| **Maaack/Godot-Game-Template** | v1.4.7 | UI/暂停菜单/选项/存档框架 | ⭐⭐⭐⭐⭐ |
| **Beehave** | v2.9.3 | Boss AI 行为树 | ⭐⭐⭐⭐⭐ |
| **XSM** | v2.0.4 (Godot 4 patched) | 玩家/Boss 状态机 | ⭐⭐⭐⭐ |
| **Dialogic** | v2.0-Alpha-20 | 战前/战后对话 | ⭐⭐⭐⭐ |
| **gdUnit4** | (待装) | 单元测试 | ⭐⭐⭐⭐ |

### 目录结构

```
godot-rpg/
├── project.godot
├── README.md
├── docs/                       # 设计文档
│   ├── GAME_DESIGN.md          # 本文档
│   ├── TECH_ARCHITECTURE.md    # 技术架构
│   └── STAGE_PLAN.md           # 实施计划
├── addons/                     # 4 个插件
│   ├── maaacks_game_template/
│   ├── beehave/
│   ├── xsm/
│   └── dialogic/
├── assets/                     # 像素素材（待收集）
│   ├── characters/
│   ├── enemies/
│   ├── environments/
│   ├── ui/
│   └── vfx/
├── audio/                      # 音效 + BGM（待收集）
│   ├── sfx/
│   └── bgm/
├── resources/                  # Resource 化数值
│   ├── player/
│   │   ├── base_player_stats.tres
│   ├── enemies/
│   │   ├── archer_stats.tres
│   │   ├── mage_stats.tres
│   │   └── knight_stats.tres
│   ├── bosses/
│   │   ├── onyx_stats.tres
│   │   └── ...
│   └── abilities/
│       ├── sword_combo.tres
│       └── ...
├── scenes/                     # 场景
│   ├── levels/
│   │   ├── chapter_1/
│   │   ├── chapter_2/
│   │   └── ...
│   ├── characters/
│   │   ├── player/
│   │   └── enemies/
│   ├── ui/
│   └── transitions/
├── scripts/                    # 脚本
│   ├── characters/
│   │   ├── player/
│   │   │   ├── player.gd
│   │   │   ├── states/         # XSM 状态
│   │   │   │   ├── idle_state.gd
│   │   │   │   ├── run_state.gd
│   │   │   │   ├── jump_state.gd
│   │   │   │   ├── attack_state.gd
│   │   │   │   ├── dodge_state.gd
│   │   │   │   ├── shield_state.gd
│   │   │   │   ├── hurt_state.gd
│   │   │   │   └── death_state.gd
│   │   │   └── actions/        # XSM Action
│   │   │       ├── move_action.gd
│   │   │       └── jump_action.gd
│   │   └── enemies/
│   │       ├── base_enemy.gd
│   │       ├── archer/
│   │       ├── mage/
│   │       ├── knight/
│   │       └── behaviors/      # Beehave 行为树 .tscn
│   │           ├── archer_behavior.tres
│   │           └── ...
│   ├── bosses/
│   │   ├── base_boss.gd
│   │   └── bosses/
│   │       ├── onyx/           # 最终 boss
│   │       └── ...
│   ├── ui/
│   ├── systems/
│   │   ├── game_state.gd       # 全局游戏状态
│   │   ├── save_system.gd      # 存档
│   │   ├── audio_manager.gd    # 音效
│   │   └── scene_manager.gd    # 场景切换
│   └── utils/
│       ├── damage_number.gd    # 伤害飘字
│       └── screen_shake.gd     # 屏幕震动
├── ui/                         # UI 场景（菜单、HUD）
│   ├── main_menu.tscn
│   ├── pause_menu.tscn
│   ├── hud.tscn                # HP/FP/技能冷却条
│   └── game_over.tscn
└── tests/                      # 单元测试（gdUnit4）
    ├── test_player.gd
    └── test_save_system.gd
```

### 核心系统设计

#### 玩家状态机（XSM）

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── States (XSM root)
│   ├── State: Idle (script: idle_state.gd)
│   ├── State: Run (script: run_state.gd)
│   ├── State: Jump (script: jump_state.gd, with substate DoubleJump)
│   ├── State: Fall (script: fall_state.gd)
│   ├── State: Attack (script: attack_state.gd, with substates Attack1/2/3)
│   ├── State: Dodge (script: dodge_state.gd)
│   ├── State: Shield (script: shield_state.gd, with substates Block/Parry)
│   ├── State: Hurt (script: hurt_state.gd)
│   └── State: Death (script: death_state.gd)
└── BeehaveTree (XSM 不便表达的复杂逻辑，如战吼/治疗/技能)
```

#### Boss AI（Beehave）

例：最终 boss「黑曜」

```
BehaviorTree
└── Selector (顶层选择器)
    ├── Sequence: Death Phase (< 0 HP)
    │   └── Action: Play Death Animation
    ├── Sequence: Rage Phase (< 33% HP)
    │   ├── Condition: Player in range
    │   └── Selector:
    │       ├── Action: Cast Ultimate
    │       └── Action: Summon Minions
    ├── Sequence: Phase 2 (66% HP)
    │   └── Selector:
    │       ├── Action: Combo Attack (3 hits)
    │       ├── Action: Cast Fireball
    │       └── Action: Teleport Behind Player
    └── Sequence: Phase 1 (100% HP)
        └── Selector:
            ├── Action: Slash Combo
            ├── Action: Shield Bash
            └── Action: Retreat and Heal
```

#### 数值 Resource 化

`base_player_stats.tres`:
```ini
script = ExtResource("PlayerStats")
max_hp = 100
max_fp = 50
attack_power = 10
defense = 5
move_speed = 220.0
jump_velocity = -480.0
attack_combo_window = 0.15
```

每个章节根据碎片调整：
`chapter_2_player_stats.tres` (override):
```ini
max_hp = 110  # +10
attack_power = 12  # +2
```

#### 存档系统（基于 GlobalState）

```gdscript
class_name SaveData extends Resource

@export var current_chapter: int = 1
@export var player_stats: PlayerStats
@export var collected_shards: Array[int] = []  # 已收集碎片
@export var unlocked_abilities: Array[String] = []
@export var defeated_bosses: Array[String] = []
@export var save_timestamp: int = 0
@export var play_time: int = 0
```

3 个手动存档位 + 1 个自动存档（每章切换时）。

---

## 🎨 视觉风格 (Visual Style)

- **像素比例**: 16x16 基础，64x64 角色
- **调色板**: 每个章节单色主调（参上表）
- **光照**: 烛火/月光/魔法光源
- **视效**: 屏幕震动、打击粒子、伤害飘字、时间减速

## 🎵 音效设计

- BGM：每章独立主题（黑曜石 boss 用变奏）
- SFX：剑击、跳跃、闪避、盾反、敌人受击、Boss 战吼
- 环境音：火把噼啪、风声、水滴

---

## 📊 工作量估算

| 阶段 | 内容 | 估算时间 |
|------|------|---------|
| Stage 0 | 项目初始化 + 插件安装 + 配置 | 半天 |
| Stage 1 | 数值 Resource 化 + PlayerStats 基类 | 1 天 |
| Stage 2 | 玩家 XSM 状态机（移动/跳跃/攻击） | 2 天 |
| Stage 3 | 玩家扩展（闪避/盾反/战吼/治疗） | 2 天 |
| Stage 4 | 敌人基类 + 弓箭手（Beehave） | 1 天 |
| Stage 5 | 其他敌人（法师/骑士/骷髅/重装/飞行/自爆） | 3 天 |
| Stage 6 | Boss 基类 + 1 个 Boss 全功能 | 2 天 |
| Stage 7 | 7 个 Boss（每个独立 AI） | 7 天 |
| Stage 8 | 关卡系统 + Chapter 1 完整关卡 | 3 天 |
| Stage 9 | 其余 6 关 + Boss 战场景 | 5 天 |
| Stage 10 | UI 框架（HUD / 菜单 / 选项） | 2 天 |
| Stage 11 | 剧情对话（Dialogic）+ 记忆系统 | 2 天 |
| Stage 12 | 存档系统（多存档位） | 1 天 |
| Stage 13 | 视觉特效（粒子/震动/飘字） | 2 天 |
| Stage 14 | 音效 + BGM 集成 | 2 天 |
| Stage 15 | 测试覆盖 + CI/CD | 2 天 |
| Stage 16 | 打磨 + 文档 + 发布 | 3 天 |
| **总计** | | **40 个工作日（约 8 周）** |

**MVP（最小可行版本）3 周**:
- Stage 0-6 (基础系统 + 玩家 + 1 敌人 + 1 Boss)
- Stage 8 (1 个完整关卡)
- Stage 10 (基础 UI)

---

## 🚦 可行性分析

### ✅ 可行（基于已有知识 + 资源）

| 维度 | 评估 | 备注 |
|------|------|------|
| **技术可行性** | ✅ 高 | 5 个插件都是 Godot 4 兼容 |
| **已有素材** | ✅ 高 | 阿迈的 Adventurer-1.5 / Evil Wizard / Knight 等可复用 |
| **架构设计** | ✅ 高 | 之前 game-2.0 重构已经验证 |
| **增量开发** | ✅ 高 | 可以逐 stage 推进，每个都能跑 |
| **学习价值** | ✅ 高 | 全程使用最佳实践 |

### 🟡 中等难度

| 维度 | 评估 | 备注 |
|------|------|------|
| **资源需求** | 🟡 中 | 需要更多素材（音效/BGM/特效/额外角色） |
| **关卡设计** | 🟡 中 | TileMap 设计需要时间和审美 |
| **平衡调优** | 🟡 中 | 数值平衡需要实际玩 |
| **时间投入** | 🟡 中 | MVP 3 周，完整 8 周 |

### 🔴 风险

| 维度 | 评估 | 缓解 |
|------|------|------|
| **资源版权** | 🟢 低 | 使用阿迈已有 + CC0 资源（kenney.nl 等） |
| **插件兼容性** | 🟢 低 | XSM 已修 Godot 4 兼容 |
| **范围蔓延** | 🟡 中 | MVP 优先，扩展后期做 |

### 关键决策

1. **从零开始 vs 基于 game-2.0** ✅ 选择从零开始（阿迈决定）
2. **故事风格** ✅ 黑暗奇幻 + 宿命主题（参考阿迈游戏代码里的"3000年后"/"宿命"线索）
3. **是否复用 game-2.0 的资源** ✅ 部分复用（characters/, enemies/ 等），整理到新结构
4. **每个章节独立的 boss 还是连续剧情** ✅ 每个章节独立 boss + 整体剧情线串联
5. **是否做 Meta 进度（死亡次数解锁等）** ❌ 暂不做，保持简单

---

## 🚀 实施路线图（Stage Plan）

### Phase A — 基础设施（本周）

- **Stage 0**: 项目初始化 + 4 个插件安装 + Godot 4 兼容补丁
- **Stage 1**: 数值 Resource 化（PlayerStats + EnemyStats 基类）
- **Stage 2**: 玩家 XSM 状态机（移动/跳跃/落地）
- **Stage 3**: 玩家攻击系统（3 段连击 + 飘字）

### Phase B — 战斗系统（第 2 周）

- **Stage 4**: 玩家扩展（闪避/盾反/战吼/治疗/受击/死亡）
- **Stage 5**: 敌人基类 + 弓箭手（Beehave 行为树）
- **Stage 6**: 法师 + 近战骑士 + 骷髅
- **Stage 7**: 重装步兵 + 飞行蝙蝠 + 自爆蜘蛛

### Phase C — Boss + 关卡（第 3-4 周）

- **Stage 8**: Boss 基类 + 多阶段机制
- **Stage 9**: 1 个 Boss 完整实现（堕落的斥候长「灰鸦」）
- **Stage 10**: Chapter 1 完整关卡（开始→战斗→Boss→过场）
- **Stage 11**: 其余 6 个 Boss + 6 个关卡

### Phase D — 内容与打磨（第 5-6 周）

- **Stage 12**: UI 框架（HUD + 主菜单 + 暂停 + 选项）
- **Stage 13**: Dialogic 剧情对话（每章战前战后）
- **Stage 14**: 存档系统（多存档位）
- **Stage 15**: 视觉特效 + 音效 + BGM

### Phase E — 测试 + 发布（第 7-8 周）

- **Stage 16**: gdUnit4 测试覆盖
- **Stage 17**: CI/CD + 文档 + 发布

### 🎯 MVP 目标（3 周完成）

MVP = Stage 0-11（核心战斗 + 1 个完整关卡 + 1 个 boss）

让阿迈能玩到：
- 启动游戏 → 主菜单
- 进入 Chapter 1
- 移动 + 攻击 + 闪避 + 盾反
- 杀几个弓箭手/法师/骑士
- 打最终 boss「灰鸦」
- 收集第 1 块碎片
- 看完战后的剧情对话
- 死亡后从存档点复活

---

## 📝 待你拍板的事

1. **故事主题**：我设计了「千年宿命」（中世纪黑暗奇幻），你 OK 吗？还是想换？
2. **章节结构**：7 章 7 boss 的设定，可以接受吗？
3. **战斗系统**：3 段剑 + 盾反 + 战吼 + 治疗 + 4 键位操作，可以接受吗？
4. **资源策略**：复用你现有素材 + 网上找免费的，OK 吗？
5. **进度**：每周完成 2-3 个 Stage，可以接受吗？

如果有任何调整告诉我，否则我开始 Stage 0。

---

*生成时间: 2026-07-18*
*执行者: 嘟嘟 (MiniMax-M3)*
*游戏名: EternalDuty (千年宿命)*
# 🗡️ EternalDuty（千年宿命）

> **2D 像素动作 ARPG** | Godot 4.6 + Jolt Physics
> 7 章 · 7 boss · 7 块碎片 · 一个关于宿命的故事

**项目代号**: `EternalDuty`
**引擎**: Godot 4.6 (Forward+ 渲染)
**物理**: Jolt Physics
**开发**: 阿迈（设计）+ 嘟嘟（架构 / 代码）
**状态**: Stage 0-5 完成，可运行的 demo 还需要 Godot 场景配置

---

## 🎮 故事

> **1267 年的波兰。** 圣剑骑士团守护圣物「千年之心」千年。如今圣物被盗，分成 7 块碎片散落在 7 处禁地。
>
> **你**是一名无名骑士——曾是圣剑骑士团的一员，三年前被逐出骑士团。如今你回到故土，发现一切已面目全非。你必须穿越 7 处禁地，集齐 7 块碎片，重新点燃「千年之心」。
>
> **但你必须付出代价**：每收集一块碎片，你会失去一段记忆。第 7 章前战，主角完全沉默——只剩战斗。

---

## 📦 项目状态

| Stage | 内容 | 状态 |
|-------|------|------|
| 0 | 项目初始化 + 4 插件 | ✅ 完成 |
| 1 | 数值 Resource 化 | ✅ 完成 |
| 2 | 核心抽象层（Stats / HitBox / HurtBox / PlayerDetectionZone / OneShotEffect / StateMachine） | ✅ 完成 |
| 3 | Player 角色（enum 状态机 + 7 状态） | ✅ 完成 |
| 4 | 敌人（BaseEnemy + Archer / Mage / Knight） | ✅ 完成 |
| 5 | Boss（BaseBoss + Chapter 1 "灰鸦" Greyr1） | ✅ 完成 |
| 6 | 1 个完整关卡 | ⏳ 需 Godot 编辑器配置 |
| 7 | UI 框架 | ⏳ 需 Godot 编辑器配置 |
| 8 | Dialogic 剧情 | ⏳ 需编辑器 |
| 9 | 存档系统 | ⏳ |
| 10 | 其余 Boss + 关卡（6 个） | ⏳ |
| 11 | 视觉特效 + 音效 | ⏳ |
| 12 | 测试 + CI | ⏳ |
| 13 | 打磨 + 发布 | ⏳ |

**当前可运行的代码**：17 个 .gd 脚本（约 1440 行）

---

## 🏗️ 架构亮点（吸收 HeartBeast 模式）

1. **Stats 节点 + 信号**：替代 `take_damage()` 函数
2. **HitBox / HurtBox 抽象**：用 Area2D 精确碰撞
3. **PlayerDetectionZone**：自动检测玩家
4. **enum 状态机**：< 10 状态用 enum
5. **Resource 数值化**：.tres 配置
6. **Beehave 行为树**：Boss AI
7. **Maaack UI 框架**：菜单
8. **Dialogic**：剧情对话

---

## 🚀 快速开始

### 1. 打开项目

```bash
# 用 Godot 4.6 打开
cd ~/Desktop/OpenClaw/godot-rpg
godot project.godot
```

### 2. 第一次打开会自动

- 生成 `.godot/` 目录
- 加载 4 个插件（Maaack / Beehave / XSM / Dialogic）
- 注册 5 个 autoload

### 3. ⚠️ 需要手动配置（见 docs/SETUP_GUIDE.md）

由于 GDScript 脚本和 Godot 场景（.tscn）是分离的，**核心逻辑已完成，但场景需要在 Godot 编辑器里创建**。

完整步骤见 `docs/SETUP_GUIDE.md`：

1. 创建 Player 场景（按节点树）
2. 创建敌人场景（Archer / Mage / Knight）
3. 创建 Greyr1 Boss 场景
4. 创建 Chapter 1 关卡
5. 创建 UI 场景（HUD / 主菜单）

---

## 📁 项目结构

```
godot-rpg/
├── project.godot
├── README.md (本文件)
├── docs/                    # 设计文档 + 设置指南
├── addons/                  # 4 个插件
├── scripts/
│   ├── core/                # 核心抽象（Stage 2）
│   ├── characters/           # Player / Enemy / Boss（Stage 3-5）
│   └── systems/              # 数值 Resource（Stage 1）
├── resources/                # .tres 数值配置
├── scenes/                   # 场景（需编辑器创建）
├── assets/                   # 像素素材
├── audio/                    # 音效 + BGM
└── tests/                    # 测试
```

---

## 🎯 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 状态机 | enum + switch | < 10 状态足够 |
| HP 管理 | Stats 节点 + 信号 | HeartBeast 模式，最优雅 |
| 攻击判定 | Area2D HitBox | 精确形状 |
| Boss AI | Beehave 行为树 | 多阶段 + 多技能 |
| 数值配置 | Resource .tres | 数据驱动 |

---

## 📜 文档

- `docs/GAME_DESIGN.md` - 完整 GDD v1.0
- `docs/DESIGN_RESEARCH.md` - HeartBeast 模式调研
- `docs/FINAL_PROJECT_PLAN.md` - 实施计划
- `docs/SETUP_GUIDE.md` - Godot 场景配置指南（创建场景）

---

## 📊 代码统计

```
scripts/core/Stats.gd           - 通用 HP 管理 + 信号
scripts/core/HitBox.gd          - 攻击 Area2D
scripts/core/HurtBox.gd         - 受击 Area2D（自动订阅）
scripts/core/PlayerDetectionZone.gd - 玩家检测
scripts/core/OneShotEffect.gd   - 一次性特效
scripts/core/StateMachine.gd    - enum 状态机基类
scripts/characters/player/Player.gd - 主控制器（7 状态）
scripts/characters/player/SwordHitbox.gd
scripts/characters/enemies/BaseEnemy.gd - 敌人基类
scripts/characters/enemies/Archer.gd - 远程弓箭手
scripts/characters/enemies/Mage.gd - 法师 + 召唤
scripts/characters/enemies/Knight.gd - 近战骑士
scripts/characters/bosses/BaseBoss.gd - Boss 基类
scripts/characters/bosses/Greyr1.gd - Chapter 1 Boss "灰鸦"
scripts/systems/player_stats.gd - Resource 配置
scripts/systems/enemy_stats.gd
scripts/systems/boss_stats.gd
```

总计：**17 个 .gd 脚本 / 1440 行**

---

## 🔧 插件列表

| 插件 | 版本 | 用途 |
|------|------|------|
| Maaack/Godot-Game-Template | v1.4.7 | UI 框架（菜单/暂停/选项/存档） |
| Beehave | v2.9.3-dev | 行为树（Boss AI） |
| XSM | v2.0.4 | 状态机（Godot 4 兼容补丁） |
| Dialogic | v2.0-Alpha-20 | 对话系统 |

---

## 🎯 下一步

要运行游戏，需要在 Godot 编辑器里：

1. 创建 Player 场景（详细步骤见 `docs/SETUP_GUIDE.md`）
2. 创建 Archer / Mage / Knight 场景
3. 创建 Greyr1 Boss 场景
4. 创建 Chapter 1 关卡
5. 创建 HUD + 主菜单

预计 1-2 小时完成场景配置后即可玩到。

---

*生成时间: 2026-07-18*
*执行者: 嘟嘟 (MiniMax-M3)*
*基于: HeartBeast ActionRPG + awesome-godot + LGD_GodotRPG*
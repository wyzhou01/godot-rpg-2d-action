# 🗡️ EternalDuty（千年宿命）

> **2D 像素动作 ARPG** | Godot 4.6 + Kenney 美术 + 自建测试套件
> 7 章 · 7 Boss · 3 种敌人 · **160 自动化测试 100% 通过** · 可玩

---

## 🎮 故事

阿迈踏上复仇之旅，挑战 7 章 7 Boss。每章独立 AI、对话、TileSet。

| 章 | Boss |
|----|------|
| 1 | 灰鸦 (Greyr1) |
| 2 | 火心 (Fireheart) |
| 3 | 冰魂 (Frost) |
| 4 | 金卫 (Goldguard) |
| 5 | 绿巫 (Greendruid) |
| 6 | 影刺 (Shadowblade) |
| 7 | 腐王 (Rotlord) |

---

## 📦 项目状态（V2.4 — Phase 4 推进中）

| Stage | 内容 | 状态 |
|-------|------|------|
| 0-5 | 架构 + Player + Enemy + Boss 基础 | ✅ |
| 6-7 | 7 章关卡 + UI 框架 + Dialogic | ✅ |
| 8-10 | 存档系统 + 6 个 Boss + 6 个关卡 | ✅ |
| 11 | 视觉/音效 | ✅ (凑合型 — 用 Kenney slime 占位) |
| 12 | 测试 + CI | ✅ **160 测试 / 9 套件 / 100% 通过** |
| **13a** | **Settings UI** | ✅ **V2.4 新增 — 音量/全屏/持久化** |
| 13b | 视觉修真 | ⏳ 待真美术 |

---

## 🏗️ 架构亮点

1. **Stats 节点 + 信号**：替代 `take_damage()` 函数
2. **HitBox / HurtBox 抽象**：用 Area2D 精确碰撞，V2.3 修真 enable/disable 同步 CollisionShape2D
3. **PlayerDetectionZone**：自动检测玩家
4. **enum 状态机**：< 10 状态用 enum
5. **Resource 数值化**：.tres 配置
6. **Beehave 行为树**：Boss AI
7. **Maaack UI 框架**：菜单
8. **Dialogic**：剧情对话
9. **Driver 模式测试 (V2.3)**：Geometry2D overlap + Stats.take_damage 真链验证 7 章通关

---

## 🚀 快速开始

### 1. 打开项目

```bash
cd ~/Desktop/OpenClaw/godot-rpg
godot project.godot
# 或 headless 测试:
bash tests/run_all_tests.sh
```

### 2. 运行游戏

主菜单 → 选章节 → 战斗 → 击败 Boss → 进入下一章

### 3. 调节设置

游戏中按 Esc → PauseMenu → Settings → 调音量/全屏 → Back

---

## 📁 项目结构

```
godot-rpg/
├── scripts/
│   ├── core/          # Stats, HitBox, HurtBox, PlayerDetectionZone, ...
│   ├── characters/    # Player, BaseEnemy, BaseBoss
│   ├── systems/       # Resource 配置 (player_stats.tres, ...)
│   ├── ui/            # HUD, PauseMenu, SettingsMenu (V2.4 新增), ...
│   └── scenes/        # SceneManager, ...
├── scenes/
│   ├── levels/        # chapter_1 ~ chapter_7
│   ├── ui/            # hud, pause_menu, settings_menu, ...
│   └── characters/    # player, bosses, enemies
├── resources/         # .tres 数据 (stats, sprite_frames, ...)
├── dialogs/           # Dialogic JSON (21 个, 7 intro + 7 boss intro + 7 defeat)
├── audio/             # Kenney 12 音频
├── tests/             # 9 套件 / 160 测试
└── docs/              # GAME_DESIGN, ROADMAP, ...
```

---

## 🎯 关键设计决策

- **V2.3 真战斗测试**：用 Driver 模式驱动伪玩家（移动 + 攻击 + 受击），7 章真打通
- **V2.4 Settings UI**：3 音量（Master/Music/SFX）+ 全屏 toggle + ConfigFile 持久化
- **safe_play() helper**：AnimationPlayer 库空时跳过，避免 ERROR 满屏
- **HitBox 修真**：enable/disable 同步启停 CollisionShape2D.disabled（修真 0 伤害 bug）
- **macOS bash 3.2**：用 case/esac 不用 declare -A 字典

---

## 📜 文档

- `DELIVERY_REPORT.md` — V2.4 最终交付报告
- `docs/GAME_DESIGN.md` — 完整 GDD
- `docs/ROADMAP.md` — 4 阶段路线图
- `docs/SETUP_GUIDE.md` — Godot 场景配置

---

## 📊 代码统计（V2.4）

```
scripts/core/         - 6 个 (Stats/HitBox/HurtBox/DetectionZone/Effect/StateMachine)
scripts/characters/   - 14 个 (Player + 3 Enemy + 7 Boss + 基类)
scripts/systems/      - 7 个 (.tres loader)
scripts/ui/           - 7 个 (HUD/PauseMenu/SettingsMenu [V2.4]/...)
scripts/scenes/       - 1 个 (SceneManager)
scripts/main_menu.gd  - 1 个

总计：35 个 .gd 脚本 (~3500 行)
30 个 .tscn 场景
273 个 PNG + 12 个音频
11 个 SpriteFrames (Player + 7 Boss + 3 Enemy)
7 个 TileSet (每章独立)
21 个对话文件 (7 intro + 7 boss intro + 7 defeat)
160 个自动化测试 (9 套件, 70s)
```

---

## 🔧 插件列表

| 插件 | 版本 | 用途 |
|------|------|------|
| Maaack/Godot-Game-Template | v1.4.7 | UI 框架（菜单/暂停/选项/存档） |
| Beehave | v2.9.3-dev | 行为树（Boss AI） |
| XSM | v2.0.4 | 状态机（Godot 4 兼容补丁） |
| Dialogic | v2.0-Alpha-20 | 对话系统 |

---

## 🎯 下一步（V2.5 候选）

- Boss 视觉修真：换真美术（Kenney 实际只有 slime 一张，需要找/做素材）
- 修真 EndScreen 加 Settings 按钮
- README 截图 / 录 GIF（itch.io 推广用）
- Settings UI 加：分辨率选项 / 控制重绑定 / 重置默认按钮
- GitHub Release V2.4 打 tag + 自动 changelog

---

*生成时间: 2026-07-22*
*执行者: 嘟嘟 (MiniMax-M3)*
*基于: HeartBeast ActionRPG + awesome-godot + LGD_GodotRPG*

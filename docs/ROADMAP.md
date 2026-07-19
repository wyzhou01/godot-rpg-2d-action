# EternalDuty 完整项目开发路线图

> **目标**：分阶段交付一个完整可玩的 2D ARPG
> **现实时间**：4-6 周（每天 1-2 小时）
> **当前状态**：2026-07-19，Phase 0 部分完成

---

## 🎯 总体时间线

```
Week 1        Week 2        Week 3-4      Week 5+
─────────────────────────────────────────────────────────
Phase 0       Phase 1       Phase 2-3     Phase 4
架构重构     Chapter 1     3-7 章       打磨+发布
1-3 天       3-4 天        10-14 天      5-7 天
```

---

## ✅ 已完成（基础已就位）

- 美术资源：273 tile + 11 SpriteFrames + 7 TileSet
- 对话系统：DialogueHelper（重写后稳定）
- 7 Boss AI：独立 _ai_tick
- 存档系统：4 槽位 + JSON
- 测试套件：137 测试 100% 通过
- 33 场景 0 Parse 错误

## ✅ Phase 0 完成（架构重构）
- Actor 基类、PlayerData autoload、InputMap 完整
- Portal2D + Fragment 收集
- Chapter 1 真关卡
- 详见 `docs/PHASE_0.md`

## ✅ Phase 1 完成（Pause UI + 7 章真关卡）
- Pause 菜单（Esc 切换）
- 7 章 intro 都成真关卡（平台 + 敌人 + Portal + Fragment）
- 7 章 boss 场景都加 PauseMenu
- 详见 `docs/PHASE_1_DONE.md`

---

## 📋 Phase 0: 架构重构（预计 1-3 天）

**目标**：把现有代码改成"真游戏"基础架构

### 0.1 Actor 基类
- [ ] 创建 `scripts/core/Actor.gd`（统一角色接口：physics process, gravity, velocity）
- [ ] Player/Enemy/Boss 继承 Actor（重构现有 BaseEnemy/BaseBoss）
- [ ] 统一移动 API：`_velocity`, `move_and_slide_with_snap()`

### 0.2 InputMap 完整
- [ ] 添加：move_left, move_right, jump, attack, dash, interact, pause
- [ ] Keyboard + Gamepad 支持
- [ ] UI 响应（不接受游戏输入）

### 0.3 PlayerData autoload
- [ ] 全局数据：score, deaths, current_chapter, fragments_collected
- [ ] 信号系统：updated, died, reset
- [ ] reset() 方法

### 0.4 Portal2D
- [ ] 创建 `scenes/objects/Portal2D.tscn`（Area2D + AnimationPlayer）
- [ ] `scripts/objects/Portal2D.gd`（fade_out 动画 + change_scene）
- [ ] next_scene export

### 0.5 Fragment 收集
- [ ] 创建 `scenes/objects/Fragment.tscn`（Area2D + Sprite）
- [ ] `scripts/objects/Fragment.gd`（拾取 + 触发对话）
- [ ] 7 个 fragment（每章 1 个，Boss 死后出现）

### 0.6 验证 DoD
- [ ] 最小关卡：2 平台 + 1 怪 + 1 portal 跳到下一关
- [ ] 跑测试：0 回归
- [ ] 文档：docs/PHASE_0_DONE.md

---

## 📋 Phase 1: Chapter 1 完整可玩（3-4 天）

**目标**：Chapter 1 真正能玩通关

### 1.1 Chapter 1 关卡设计
- [ ] 起点（安全区）→ 3 平台跳跃 → 5 怪战斗 → boss 战 → portal
- [ ] 真 TileMap 铺地（用 Kenney grass tiles）
- [ ] 装饰物（草、石头、树）
- [ ] 检查点（mid-level）

### 1.2 完整 Player 动画
- [ ] idle / run / jump / fall / attack / hurt / death
- [ ] 用 Kenney p1 精灵图（已有）
- [ ] SpriteFrames animation 调通

### 1.3 完整 Enemy 动画
- [ ] Knight: idle / run / attack / hurt / death
- [ ] Archer: idle / run / attack / hurt / death
- [ ] Mage: idle / run / attack / hurt / death
- [ ] AnimationPlayer 调通

### 1.4 完整 Boss 动画
- [ ] Greyr1: idle / attack_1 / attack_2 / hurt / death
- [ ] 7 个 Boss 同模式

### 1.5 Pause UI
- [ ] 暂停按钮 / P 键
- [ ] 暂停菜单（继续 / 退出主菜单）
- [ ] 半透明黑遮罩

### 1.6 死亡重生
- [ ] Player HP=0 → 死亡动画 → 1.5s → respawn
- [ ] 减少 HP 或保持（可选）
- [ ] DeathCounter

### 1.7 验证 DoD
- [ ] Chapter 1 完整玩通（5+ 分钟）
- [ ] 跑测试：0 回归
- [ ] 文档：docs/PHASE_1_DONE.md
- [ ] 给阿迈 demo 一次

---

## 📋 Phase 2: 3 章可玩（5-7 天）

### 2.1 Chapter 2-3 关卡
- [ ] Chapter 2: 雪山修道院（ice tiles）
- [ ] Chapter 3: 腐木森林（dirt + dead tree tiles）
- [ ] 每章 5-8 怪 + 1 Boss

### 2.2 3 个 Boss 平衡
- [ ] Greyr1 HP=200, Frost=400, Rotlord=600
- [ ] 攻击模式/速度差异化
- [ ] 玩家能 1-3 次击败

### 2.3 7 碎片收集系统
- [ ] 7 Fragment 散布在 7 章
- [ ] HUD 显示 7 个格子（已收集 ✓）
- [ ] 杀 Boss 后掉 Fragment

### 2.4 HUD 完善
- [ ] HP/FP 进度条
- [ ] 7 碎片格子
- [ ] 当前章节名
- [ ] 死亡次数

### 2.5 Save/Load 实际
- [ ] 保存：章节 + 位置 + HP + 碎片
- [ ] 读取：恢复玩家位置
- [ ] 4 槽位

### 2.6 DoD
- [ ] 玩 1-3 章，看到 3 碎片
- [ ] 测试 0 回归
- [ ] demo

---

## 📋 Phase 3: 完整 7 章（10-14 天）

### 3.1 Chapter 4-7 关卡
- [ ] Ch4: 黄金圣殿
- [ ] Ch5: 烈焰之心
- [ ] Ch6: 翡翠德鲁伊圣地
- [ ] Ch7: 黑曜石王座

### 3.2 4 个 Boss
- [ ] Goldguard HP=800
- [ ] Fireheart HP=1000
- [ ] Greendruid HP=1200
- [ ] Onyx HP=1500（最终 Boss，多阶段）

### 3.3 失忆叙事
- [ ] 7 个"你失去了...记忆"提示
- [ ] Chapter 7 前玩家完全沉默
- [ ] Boss 战台词触发完整回忆

### 3.4 结局
- [ ] EndScreen 场景
- [ ] "你收集了所有碎片"
- [ ] Total playtime + Death count
- [ ] Replay / Back to Menu

### 3.5 DoD
- [ ] 完整通关 7 章
- [ ] 结局触发
- [ ] demo

---

## 📋 Phase 4: 打磨 + 发布（5-7 天）

### 4.1 平衡
- [ ] 5+ 次自己玩通，调整数字
- [ ] 死亡次数统计
- [ ] 难度曲线合理

### 4.2 教学
- [ ] Chapter 1 前加 movement tutorial
- [ ] "按 W/A/S/D 移动"提示
- [ ] "按 J 攻击"提示

### 4.3 Settings
- [ ] 音量（master/BGM/SFX）
- [ ] 分辨率
- [ ] 全屏

### 4.4 发布
- [ ] 截图
- [ ] README
- [ ] GitHub Release
- [ ] itch.io (可选)

### 4.5 DoD
- [ ] 朋友试玩 30 分钟不出 bug
- [ ] 完整游戏体验

---

## 📅 每日工作模板

```
今天 1-2 小时，做：
[ ] 1. 选一个 Phase 的任务
[ ] 2. 看 docs/PHASE_X.md
[ ] 3. 写代码
[ ] 4. 跑测试 (bash tests/run_all_tests.sh)
[ ] 5. 玩一下确认没破
[ ] 6. git commit
```

## 🎯 明天开始

**今天**：Phase 0 开始 - Actor 基类 + InputMap + PlayerData
**今天 2 小时后**：最小可玩 demo

## 📚 参考资料

- **Lango_GodotRPG** (类似 Zelda 风格): https://github.com/Delta12Studio/Lango_GodotRPG
- **GDQuest 2D Platformer**: https://github.com/CoreteamEU/godot-beginner-2d-platformer
- **HeartBeast Action RPG**: https://www.youtube.com/c/HeartBeast
- **Kenney 美术**: https://kenney.nl/

---

_最后更新: 2026-07-19 11:55_
_当前: Phase 0 进行中_
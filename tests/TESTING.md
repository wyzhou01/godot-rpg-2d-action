# EternalDuty 自动化测试套件

> **目标**：嘟嘟完成游戏后，**自己跑完全部测试**，确保交付时无 bug。

## 测试结果（最终）

```
==============================================================
  ETERNALDUTY 自动化测试套件
  开始时间: 2026-07-19 11:09:48
==============================================================

  ✅ scene_validation: 49 PASS / 0 FAIL (2s)
  ✅ resources:        52 PASS / 0 FAIL (2s)
  ✅ dialogue:         11 PASS / 0 FAIL (8s)
  ✅ combat:           13 PASS / 0 FAIL (12s)
  ✅ save_system:       6 PASS / 0 FAIL (2s)
  ✅ e2e_full_game:     3 PASS / 0 FAIL (17s)

==============================================================
  最终报告
==============================================================
  通过: 134 / 134
  失败套件: 0 / 6
  总耗时: 43s
  ✅ 全部测试通过
==============================================================
```

## 测试架构

```
tests/
├── test_framework.gd          # 基础类（assert、报告、helper）
├── run_all_tests.sh           # 主入口（自建 bash，零依赖）
├── test_scene_validation.gd   # 30 场景 + 关键节点检查
├── test_resources.gd          # PNG/JSON/音频/SpriteFrames/TileSet
├── test_dialogue.gd           # DialogueHelper 推进/信号
├── test_combat.gd             # 玩家移动 + 攻击 + 受伤
├── test_save_system.gd        # 存档/读档
├── test_e2e_full_game.gd      # 7 章完整流程
└── TESTING.md                 # 本文档
```

## 怎么跑

```bash
# 全套件（推荐）
bash tests/run_all_tests.sh

# 单测
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/test_dialogue.tscn

# 全部场景 Parse 检查
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://scenes/levels/chapter_1/chapter_1_intro.tscn
```

## CI 集成

GitHub Actions 在 `.github/workflows/headless-validate.yml`：
- `static-check` - Python 静态检查
- `godot-headless` - 加载验证
- `automated-tests` - 跑全部 134 测试

每次 push / PR 自动跑。结果作为 artifact 上传。

## 测试覆盖矩阵

| 系统 | 单元 | 集成 | E2E |
|------|------|------|-----|
| 场景加载 | ✅ 49 | | ✅ |
| 资源完整性 | ✅ 52 | | |
| DialogueHelper | ✅ 11 | ✅ | ✅ |
| Player 状态机 | | ✅ | ✅ |
| 战斗（攻击/受击） | | ✅ | ✅ |
| 存档/读档 | ✅ 6 | | ✅ |
| 章节切换 | | | ✅ 14 阶段 |
| Boss 死亡触发 | | | ✅ 7/7 |
| Camera 跟随 | | ✅ | ✅ |
| HUD 更新 | | ✅ | ✅ |
| BGM 切换 | | | ✅ |

## 通过测试发现并修复的真实 bug

| # | Bug | 修复 |
|---|-----|------|
| 1 | Ground collision 失效（shape size 丢失） | sub_resource 加 size 属性 |
| 2 | Player/Enemy sprite 翻面方向反 | _update_sprite_direction 修正 |
| 3 | play_anim("run") 错误（应为 "walk"） | 改名 |
| 4 | DialogueHelper 3 次后卡死（busy parent） | call_deferred + await |
| 5 | Boss 场景播章节 intro | boss .tscn 显式 set intro_dialog_path |
| 6 | Boss 死亡信号没触发（时序） | _ready 重排 |

**测试不只是 QA 工具，是发现 bug 的核心手段**。

## 设计原则

1. **零依赖** - 纯 GDScript + Bash
2. **Headless 友好** - 不需显示
3. **快速反馈** - 43s 完整套件
4. **可扩展** - 加新测试 = 加新方法
5. **可读报告** - PASS/FAIL + 时间 + 消息
6. **CI 集成** - GitHub Actions

## 限制与未来

- **当前不能测试**：视觉输出（精灵、动画帧）、音频质量、性能
- **未来可加**：GUT 集成（更细粒度）、CI 截图比对、Gameplay recording

---

_最后更新: 2026-07-19 11:10_
_总测试: 134 个_
_通过率: 100%_
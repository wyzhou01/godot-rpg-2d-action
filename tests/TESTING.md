# EternalDuty 自动化测试套件

> **目标**：嘟嘟完成游戏后，**自己跑完全部测试**，确保交付时无 bug。

---

## 测试架构

```
tests/
├── test_framework.gd          # 基础类（断言、报告、helper）
├── run_all_tests.gd           # 主入口（顺序跑全部）
├── test_scene_validation.gd   # 30 个 .tscn 加载 + 资源检查
├── test_resources.gd          # PNG/JSON/音频 完整性
├── test_dialogue.gd           # DialogueHelper 推进/信号
├── test_combat.gd             # 玩家移动 + 攻击 + 受伤
├── test_save_system.gd        # 存档/读档
└── test_e2e_full_game.gd      # 7 章完整流程
```

## 怎么跑

```bash
# 单测
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/test_dialogue.gd

# 全部测试
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/run_all_tests.gd

# 详细输出（建议这样跑）
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/run_all_tests.gd 2>&1 | tee test_report.log
```

## 输出格式

```
========================================
[SUITE] dialogue_test
========================================
[PASS] test_dialogue_show
[PASS] test_dialogue_advance
[PASS] test_dialogue_signals
[FAIL] test_dialogue_cleanup
       Expected: _is_showing = false
       Got: _is_showing = true
========================================
SUMMARY: 8 PASS / 1 FAIL / 0 ERROR
========================================
```

## CI 集成

GitHub Actions 跑：
- 每次 push
- 每次 PR
- 输出 test_report.log 作为 artifact

## 设计原则

1. **不依赖 GUT/外部库** — 纯 GDScript，零依赖
2. **Headless 友好** — 所有测试都不需要显示
3. **快速反馈** — 完整套件 < 5 分钟
4. **可扩展** — 加新测试 = 加新方法
5. **可读报告** — 失败时打印上下文

## 测试覆盖矩阵

| 系统 | 单元 | 集成 | E2E |
|------|------|------|-----|
| 场景加载 | ✅ | | ✅ |
| 资源完整性 | ✅ | | |
| DialogueHelper | ✅ | ✅ | ✅ |
| Player 状态机 | ✅ | ✅ | ✅ |
| Boss AI | ✅ | ✅ | ✅ |
| 战斗（攻击/受击） | | ✅ | ✅ |
| 存档/读档 | ✅ | | ✅ |
| 章节切换 | | | ✅ |
| Camera 跟随 | | ✅ | ✅ |
| HUD 更新 | | ✅ | ✅ |
| BGM 切换 | | | ✅ |

---

_测试不是负担，是让你以后不用每次手动测 5 分钟_
_测试通过 = 交付质量保证_
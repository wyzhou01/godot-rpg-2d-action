#!/bin/bash
## ETERNALDUTY 自动化测试套件 - 主入口
## 跑全部 6 个测试套件，汇总报告

set -e

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

REPORT_FILE="tests/test_report.log"
> "$REPORT_FILE"

echo "==============================================================" | tee -a "$REPORT_FILE"
echo "  ETERNALDUTY 自动化测试套件" | tee -a "$REPORT_FILE"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
echo "  项目目录: $PROJECT_DIR" | tee -a "$REPORT_FILE"
echo "==============================================================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
TOTAL_TIME=0
SUITES=(
    "scene_validation:res://tests/test_scene_validation.gd"
    "resources:res://tests/test_resources.gd"
    "dialogue:res://tests/test_dialogue.gd"
    "combat:res://tests/test_combat.gd"
    "save_system:res://tests/test_save_system.gd"
    "e2e_full_game:res://tests/test_e2e_full_game.gd"
)

for suite in "${SUITES[@]}"; do
    name="${suite%%:*}"
    path="${suite##*:}"
    scene_path="${path#res://}"
    
    echo "────────────────────────────────────────────────────────────" | tee -a "$REPORT_FILE"
    echo "  ▶ 套件: $name" | tee -a "$REPORT_FILE"
    echo "────────────────────────────────────────────────────────────" | tee -a "$REPORT_FILE"
    
    start=$(date +%s%3N)
    
    # 跑测试
    if "$GODOT_BIN" --headless --path "$PROJECT_DIR" "$scene_path" 2>&1 | tee -a "$REPORT_FILE"; then
        end=$(date +%s%3N)
        elapsed=$((end - start))
        TOTAL_TIME=$((TOTAL_TIME + elapsed))
        echo "  ⏱ 耗时: ${elapsed}ms" | tee -a "$REPORT_FILE"
    else
        end=$(date +%s%3N)
        elapsed=$((end - start))
        TOTAL_TIME=$((TOTAL_TIME + elapsed))
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        echo "  ❌ $name FAILED (${elapsed}ms)" | tee -a "$REPORT_FILE"
    fi
    echo "" | tee -a "$REPORT_FILE"
done

echo "==============================================================" | tee -a "$REPORT_FILE"
echo "  最终报告" | tee -a "$REPORT_FILE"
echo "==============================================================" | tee -a "$REPORT_FILE"
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
echo "  总耗时: ${TOTAL_TIME}ms" | tee -a "$REPORT_FILE"
echo "  套件数: ${#SUITES[@]}" | tee -a "$REPORT_FILE"
echo "  失败套件: $TOTAL_FAIL" | tee -a "$REPORT_FILE"
echo "  报告文件: $REPORT_FILE" | tee -a "$REPORT_FILE"

if [ "$TOTAL_FAIL" -gt 0 ]; then
    echo "" | tee -a "$REPORT_FILE"
    echo "  ❌ 至少一个测试套件失败" | tee -a "$REPORT_FILE"
    exit 1
else
    echo "" | tee -a "$REPORT_FILE"
    echo "  ✅ 全部测试通过" | tee -a "$REPORT_FILE"
    exit 0
fi
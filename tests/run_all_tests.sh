#!/bin/bash
## ETERNALDUTY 自动化测试套件 - 主入口
## 跑全部 6 个测试套件，汇总报告

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

# 套件 + 超时（秒）— 不用 bash 关联数组，macOS bash 3.2 不支持 -A
suite_timeout() {
    case "$1" in
        scene_validation) echo 15 ;;
        resources) echo 15 ;;
        dialogue) echo 30 ;;
        combat) echo 60 ;;
        save_system) echo 15 ;;
        e2e_full_game) echo 120 ;;
        boss_names) echo 15 ;;
        playthrough) echo 90 ;;
        combat_battle) echo 90 ;;
        settings) echo 30 ;;
        real_input_combat) echo 150 ;;
        dialog_real) echo 30 ;;
        save_load_real) echo 15 ;;
        settings_runtime) echo 30 ;;
        asset_integrity) echo 30 ;;
        dialog_localization) echo 15 ;;
        death_retry) echo 30 ;;
        perf_budget) echo 60 ;;
        playthrough_full) echo 60 ;;
        pause_menu_ui) echo 30 ;;
        end_screen_ui) echo 30 ;;
        save_load_menu_ui) echo 30 ;;
        player_behavior_advanced) echo 30 ;;
        *) echo 30 ;;
    esac
}

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TESTS=0
TOTAL_TIME=0

for suite in scene_validation resources dialogue combat save_system e2e_full_game boss_names playthrough combat_battle settings real_input_combat dialog_real save_load_real settings_runtime asset_integrity dialog_localization death_retry perf_budget playthrough_full pause_menu_ui end_screen_ui save_load_menu_ui player_behavior_advanced; do
    timeout=$(suite_timeout "$suite")
    scene_path="res://tests/test_${suite}.tscn"
    
    echo "────────────────────────────────────────────────────────────" | tee -a "$REPORT_FILE"
    echo "  ▶ 套件: $suite (timeout ${timeout}s)" | tee -a "$REPORT_FILE"
    echo "────────────────────────────────────────────────────────────" | tee -a "$REPORT_FILE"
    
    start=$(date +%s)
    
    # 跑测试 — 用 bash 自己的超时机制
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" "$scene_path" > /tmp/suite_$suite.log 2>&1 &
    pid=$!
    # bash sleep N 等待最多 timeout 秒
    elapsed=0
    while kill -0 $pid 2>/dev/null && [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed+1))
    done
    if kill -0 $pid 2>/dev/null; then
        kill -9 $pid 2>/dev/null
        wait $pid 2>/dev/null
        echo "  ⚠ TIMEOUT after ${timeout}s" | tee -a "$REPORT_FILE"
    else
        wait $pid 2>/dev/null
    fi
    exit_code=$?
    
    end=$(date +%s)
    elapsed=$((end - start))
    TOTAL_TIME=$((TOTAL_TIME + elapsed))
    
    # 解析结果
    if grep -q "ALL TESTS PASSED" /tmp/suite_$suite.log; then
        # 提取测试数
        results=$(grep "Results:" /tmp/suite_$suite.log | head -1)
        passed=$(echo "$results" | grep -oE "[0-9]+ PASS" | grep -oE "[0-9]+")
        total=$(grep "Total tests:" /tmp/suite_$suite.log | grep -oE "[0-9]+" | head -1)
        if [ -n "$passed" ]; then TOTAL_PASS=$((TOTAL_PASS + passed)); fi
        if [ -n "$total" ]; then TOTAL_TESTS=$((TOTAL_TESTS + total)); fi
        echo "  ✅ $results (${elapsed}s)" | tee -a "$REPORT_FILE"
    elif grep -q "TEST SUITE FAILED" /tmp/suite_$suite.log; then
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        results=$(grep "Results:" /tmp/suite_$suite.log | head -1)
        echo "  ❌ FAILED: $results" | tee -a "$REPORT_FILE"
        # 列出失败测试
        grep -A 1 "❌ \[FAIL\]" /tmp/suite_$suite.log | tee -a "$REPORT_FILE" | head -10
    else
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        echo "  ❌ UNKNOWN: exit=$exit_code" | tee -a "$REPORT_FILE"
        tail -10 /tmp/suite_$suite.log | tee -a "$REPORT_FILE"
    fi
    echo "" | tee -a "$REPORT_FILE"
done

echo "==============================================================" | tee -a "$REPORT_FILE"
echo "  最终报告" | tee -a "$REPORT_FILE"
echo "==============================================================" | tee -a "$REPORT_FILE"
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
echo "  总耗时: ${TOTAL_TIME}s" | tee -a "$REPORT_FILE"
echo "  套件数: 22" | tee -a "$REPORT_FILE"
echo "  通过: $TOTAL_PASS" | tee -a "$REPORT_FILE"
echo "  失败套件: $TOTAL_FAIL" | tee -a "$REPORT_FILE"
echo "  总测试数: $TOTAL_TESTS" | tee -a "$REPORT_FILE"
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
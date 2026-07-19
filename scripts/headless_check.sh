#!/usr/bin/env bash
# EternalDuty Headless 验证脚本
# 用法: bash scripts/headless_check.sh
#
# 跑 Godot headless 模式（编辑器 + 退出），捕获所有 parse error
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/.headless-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/headless_${TIMESTAMP}.log"
ERRORS_FILE="${LOG_DIR}/errors_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

echo "==================================================="
echo "  EternalDuty Headless 验证"
echo "==================================================="
echo "项目根: ${PROJECT_ROOT}"
echo "日志:   ${LOG_FILE}"
echo ""

# 1. 找 Godot 命令
GODOT=""
for cmd in \
    "/Applications/Godot.app/Contents/MacOS/Godot" \
    "/Applications/Godot_4.app/Contents/MacOS/Godot" \
    "${HOME}/Applications/Godot.app/Contents/MacOS/Godot" \
    "godot" "godot4"
do
    if [ -x "${cmd}" ]; then
        GODOT="${cmd}"
        break
    elif command -v "${cmd}" >/dev/null 2>&1; then
        GODOT="$(command -v ${cmd})"
        break
    fi
done

if [ -z "${GODOT}" ]; then
    echo "❌ 找不到 Godot 命令"
    echo ""
    echo "请安装 Godot 4.6:"
    echo "  brew install --cask godot"
    echo "  或从 https://godotengine.org/download 下载"
    exit 1
fi

echo "Godot: ${GODOT}"
GODOT_VERSION=$("${GODOT}" --version 2>&1 | head -1)
echo "版本: ${GODOT_VERSION}"
echo ""

# 2. 清空 .godot cache（确保重新生成）
if [ -d "${PROJECT_ROOT}/.godot" ]; then
    echo "🗑️  清空 .godot cache..."
    rm -rf "${PROJECT_ROOT}/.godot"
fi

# 3. 跑 headless 验证
echo "▶️  运行: ${GODOT} --headless --editor --quit --verbose"
echo "   (首次运行会重新生成 .godot/，可能需要 30-60 秒)"
echo ""

cd "${PROJECT_ROOT}"

set +e
"${GODOT}" --headless --editor --quit --verbose > "${LOG_FILE}" 2>&1
EXIT_CODE=$?
set -e

# 4. 提取错误
echo "==================================================="
echo "  错误/警告提取"
echo "==================================================="
grep -E "SCRIPT ERROR|Parse Error|ERROR|Unable to load|Failed to compile" \
    "${LOG_FILE}" > "${ERRORS_FILE}" || true

ERROR_COUNT=$(wc -l < "${ERRORS_FILE}" 2>/dev/null || echo 0)

if [ "${ERROR_COUNT}" -gt 0 ]; then
    echo "❌ 发现 ${ERROR_COUNT} 条错误/警告:"
    echo ""
    cat "${ERRORS_FILE}"
    echo ""
    echo "完整日志: ${LOG_FILE}"
    echo ""
    echo "复制上面 '❌' 开头的行发给嘟嘟修"
    exit 1
fi

echo "✅ 无错误！"
echo "完整日志: ${LOG_FILE}"

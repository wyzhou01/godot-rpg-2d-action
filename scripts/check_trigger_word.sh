#!/usr/bin/env bash
# check_trigger_word.sh — 检测 git 改动里是否含 trigger word (修真)
# 用途：
#   - pre-commit hook：检测 staged files
#   - CI：检测 origin/main..HEAD diff
#
# 模式：
#   staged  (default) — 检查 git diff --cached 的文件
#   diff              — 检查 origin/main..HEAD 的所有改动
#
# 返回：
#   0 — 没找到 trigger word
#   1 — 找到 trigger word (并打印位置)
#   2 — 脚本使用错误

set -euo pipefail

# ====== 配置 ======
TRIGGER_WORDS=("修真")
MODE="staged"
BASE_REF="origin/main"
# 白名单：检测工具自身文件 (这些文件必须含 trigger word 才能工作)
# 用逗号分隔的 glob pattern, 如 "*.githooks/pre-commit,scripts/check_trigger_word.sh"
EXCLUDE_PATTERNS=""

usage() {
  echo "用法: $0 [staged|diff] [base-ref] [--exclude PATTERN,...]"
  echo ""
  echo "  staged                          (default) 检查 git staged files"
  echo "  diff [base-ref]                 检查 base..HEAD 之间的所有文件改动"
  echo "                                    默认 base-ref = origin/main"
  echo "  --exclude PATTERN,...           跳过这些 glob pattern (用逗号分隔)"
  echo ""
  echo "示例："
  echo "  $0 staged"
  echo "  $0 diff origin/main"
  echo "  $0 staged --exclude 'scripts/check_trigger_word.sh,.githooks/*'"
  exit 2
}

# ====== 参数解析 ======
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    staged) MODE="staged"; shift ;;
    diff) MODE="diff"; BASE_REF="${2:-origin/main}"; shift 2 ;;
    --exclude) EXCLUDE_PATTERNS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "❌ 未知参数: $1"; usage ;;
  esac
done

# 检查文件是否在白名单内
is_excluded() {
  local file="$1"
  [[ -z "$EXCLUDE_PATTERNS" ]] && return 1
  IFS=',' read -ra PATTERNS <<< "$EXCLUDE_PATTERNS"
  for pattern in "${PATTERNS[@]}"; do
    # 去除空白
    pattern="$(echo "$pattern" | xargs)"
    # 用 bash pattern matching
    case "$file" in
      $pattern) return 0 ;;
    esac
  done
  return 1
}

# ====== 检查逻辑 ======
FAILED=0

check_word_in_file() {
  local word="$1"
  local file="$2"
  local label="$3"
  # 用 grep -F (literal) 找字面 trigger word
  # -n 显示行号, --label 显示来源标签
  if grep -qF -- "$word" "$file" 2>/dev/null; then
    echo "❌ TRIGGER WORD '$word' found in $label"
    echo "   file: $file"
    grep -nF -- "$word" "$file" 2>/dev/null | head -5 | sed 's/^/   /'
    FAILED=1
  fi
}

check_word_in_string() {
  local word="$1"
  local text="$2"
  local label="$3"
  if echo "$text" | grep -qF -- "$word"; then
    echo "❌ TRIGGER WORD '$word' found in $label"
    echo "$text" | grep -nF -- "$word" | head -5 | sed 's/^/   /'
    FAILED=1
  fi
}

if [[ "$MODE" == "staged" ]]; then
  # ====== pre-commit 模式：检查 staged files + 待提交 commit message ======
  echo "🔍 检查 staged files + commit message (pre-commit) ..."

  # 1. 检查 staged files 内容
  STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
  for word in "${TRIGGER_WORDS[@]}"; do
    for file in $STAGED_FILES; do
      # 删除的文件跳过
      [[ -f "$file" ]] || continue
      # 二进制文件跳过
      file -b --mime "$file" 2>/dev/null | grep -q "^text/" || continue
      # 白名单跳过 (检测工具自身)
      is_excluded "$file" && continue
      check_word_in_file "$word" "$file" "staged:$file"
    done
  done

  # 2. 检查待提交 commit message（通过 .git/COMMIT_EDITMSG 或 -m 参数）
  COMMIT_MSG=""
  if [[ -f "${GIT_DIR:-.git}/COMMIT_EDITMSG" ]]; then
    COMMIT_MSG=$(cat "${GIT_DIR:-.git}/COMMIT_EDITMSG")
  elif commit_msg=$(git log -1 --pretty=%B 2>/dev/null); then
    # 兜底：检查上一次 commit（pre-commit hook 时已 commit 但 message 还没固化时）
    COMMIT_MSG="$commit_msg"
  fi
  for word in "${TRIGGER_WORDS[@]}"; do
    check_word_in_string "$word" "$COMMIT_MSG" "commit message"
  done

elif [[ "$MODE" == "diff" ]]; then
  # ====== CI 模式：检查 base..HEAD 的文件内容 diff (不查历史 commit messages) ======
  #
  # 为什么 CI 不检查 commit messages？
  # - 历史 commit messages 已经被 git 固化，不会再次让 agent runtime 卡死
  #   （除非有工具把 git log 输出给 agent，但那是工具设计问题，不是 commit 问题）
  # - 修真危机本质是 agent 实时输出含 trigger word 导致卡死
  # - working tree 文件内容如果含 trigger word，未来 agent read 时会卡死 → 必须拦截
  #
  echo "🔍 检查 $BASE_REF..HEAD 文件内容 diff (CI) ..."

  if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    echo "⚠️  $BASE_REF 不存在，无法检查 diff (可能在 fork 或首次 push)。跳过。"
    exit 0
  fi

  DIFF_FILES=$(git diff --name-only "$BASE_REF..HEAD" --diff-filter=ACMR 2>/dev/null || true)
  for word in "${TRIGGER_WORDS[@]}"; do
    for file in $DIFF_FILES; do
      [[ -f "$file" ]] || continue
      file -b --mime "$file" 2>/dev/null | grep -q "^text/" || continue
      # 白名单跳过 (检测工具自身)
      is_excluded "$file" && continue
      check_word_in_file "$word" "$file" "diff:$file"
    done
  done
fi

# ====== 结果 ======
if [[ $FAILED -eq 0 ]]; then
  echo "✅ 无 trigger word"
  exit 0
else
  echo ""
  echo "=========================================="
  echo "🚫 检测到 trigger word，请修改后再 commit"
  echo ""
  echo "提示：trigger word 是 agent runtime 的禁词，会导致"
  echo "      'Agent couldn't generate a response' 错误。"
  echo "      请用同义词 (修复/修订/调整/完善) 代替。"
  echo "=========================================="
  exit 1
fi
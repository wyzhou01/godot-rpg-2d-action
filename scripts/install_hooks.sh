#!/usr/bin/env bash
# install_hooks.sh — 安装 git hooks (pre-commit)
# 把 .githooks/pre-commit 软链到 .git/hooks/pre-commit
#
# 用法：
#   bash scripts/install_hooks.sh
#
# 卸载：
#   rm .git/hooks/pre-commit

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIT_DIR="${GIT_DIR:-$REPO_ROOT/.git}"
HOOKS_SRC="$REPO_ROOT/.githooks"
HOOK_NAME="pre-commit"

if [[ ! -d "$GIT_DIR" ]]; then
  echo "❌ 不是 git 仓库 (找不到 $GIT_DIR)"
  exit 1
fi

if [[ ! -f "$HOOKS_SRC/$HOOK_NAME" ]]; then
  echo "❌ 找不到 $HOOKS_SRC/$HOOK_NAME"
  exit 1
fi

# 检查是否已安装
if [[ -L "$GIT_DIR/hooks/$HOOK_NAME" ]] && [[ "$(readlink "$GIT_DIR/hooks/$HOOK_NAME")" == "$HOOKS_SRC/$HOOK_NAME" ]]; then
  echo "✅ pre-commit hook 已安装 (symlink → $HOOKS_SRC/$HOOK_NAME)"
  exit 0
fi

# 如果已有同名 hook (不是 symlink)，先备份
if [[ -e "$GIT_DIR/hooks/$HOOK_NAME" ]]; then
  BACKUP="$GIT_DIR/hooks/${HOOK_NAME}.bak.$(date +%Y%m%d-%H%M%S)"
  echo "⚠️  已存在 $HOOK_NAME，备份到 $BACKUP"
  mv "$GIT_DIR/hooks/$HOOK_NAME" "$BACKUP"
fi

# 设置 git hooksPath 指向 .githooks/ (推荐方式，无需每个文件 symlink)
git config core.hooksPath "$HOOKS_SRC"
echo "✅ 已设置 git core.hooksPath = $HOOKS_SRC"
echo ""
echo "现在 git 会自动从 $HOOKS_SRC/ 加载所有 hook。"
echo "已安装 hook: $(ls "$HOOKS_SRC")"
echo ""
echo "验证：bash scripts/check_trigger_word.sh"
echo "卸载：git config --unset core.hooksPath"
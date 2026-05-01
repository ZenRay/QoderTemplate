#!/bin/bash
# .qoderwork/hooks/auto-lint.sh
# PostToolUse Hook — 文件写入/编辑后自动执行 Lint 检查
# 退出码 0 = 继续，非 0 = 非阻断性错误（显示给用户）

set -uo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.path // empty')

if [ -z "$file" ] || [ ! -f "$file" ]; then
  exit 0
fi

exit_code=0

case "$file" in
  *.js|*.jsx|*.ts|*.tsx)
    if command -v npx &>/dev/null; then
      npx eslint "$file" --fix --quiet 2>&1 || exit_code=$?
    fi
    ;;
  *.py)
    if command -v ruff &>/dev/null; then
      ruff check "$file" --fix --quiet 2>&1 || exit_code=$?
    elif command -v flake8 &>/dev/null; then
      flake8 "$file" 2>&1 || exit_code=$?
    fi
    ;;
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$file" 2>&1 || exit_code=$?
    fi
    ;;
  *.rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$file" 2>&1 || exit_code=$?
    fi
    ;;
  *.sh)
    if command -v shellcheck &>/dev/null; then
      shellcheck "$file" 2>&1 || exit_code=$?
    fi
    ;;
esac

exit $exit_code

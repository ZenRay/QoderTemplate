#!/bin/bash
# .qoderwork/hooks/security-gate.sh
# PreToolUse Hook — 拦截高危 Bash 命令
# 退出码 2 = 阻断执行，并将 stderr 注入会话

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# 高危命令模式匹配
DANGER_PATTERNS=(
  'rm\s+-[rRf]'
  'rm\s+--recursive'
  'DROP\s+TABLE'
  'DROP\s+DATABASE'
  'TRUNCATE\s+TABLE'
  '>\s*/dev/sd'
  'dd\s+if='
  'mkfs\.'
  'chmod\s+-R\s+777'
  'sudo\s+rm'
  ':(){:|:&};:'
)

for pattern in "${DANGER_PATTERNS[@]}"; do
  if echo "$command" | grep -qiE "$pattern"; then
    echo "安全门拦截: 检测到高危指令 [$command]。请使用受控脚本替代，或联系项目负责人确认。" >&2
    exit 2
  fi
done

exit 0

#!/bin/bash
# .qoderwork/hooks/log-failure.sh
# PostToolUseFailure Hook — 记录工具执行失败日志

set -uo pipefail

LOG_DIR=".qoderwork/logs"
LOG_FILE="$LOG_DIR/failure.log"

mkdir -p "$LOG_DIR"

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // "unknown"')
error=$(echo "$input" | jq -r '.error // ""')
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$timestamp] FAILURE | tool=$tool | error=$error" >> "$LOG_FILE"

exit 0

#!/bin/bash
# .qoderwork/hooks/knowledge-trigger.sh
# PreCompact / SessionEnd Hook — 提示执行知识提炼归档
# 退出码 0 = 不阻断，仅通过 stderr 注入提示

set -uo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
trigger=$(echo "$input" | jq -r '.trigger // empty')
end_reason=$(echo "$input" | jq -r '.end_reason // empty')

# 日志记录
LOG_DIR=".qoderwork/logs"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] KnowledgeTrigger | session=$session_id | trigger=$trigger | end_reason=$end_reason" >> "$LOG_DIR/knowledge-trigger.log"

# 向 Agent 会话注入知识提炼提示
cat >&2 << 'PROMPT'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝  知识归档提醒
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前会话即将压缩/结束。

如果本次会话包含以下内容，建议立即归档：
  • 重要的技术决策或方案对比
  • 背景信息、业务上下文
  • 可复用的经验或最佳实践
  • 后续行动项

执行方式：
  告诉 Qoder："执行 KnowledgeExtractor，归档本次会话"
  或："整理本次会话要点，存到个人知识库"

归档目标：~/Documents/PersonalKnowledge/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROMPT

exit 0

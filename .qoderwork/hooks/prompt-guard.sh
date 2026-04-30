#!/bin/bash
# .qoderwork/hooks/prompt-guard.sh
# UserPromptSubmit Hook — 提示词注入防护
# 退出码 2 = 阻断，stderr 内容注入会话

set -uo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')

# prompt 为空则放行
[ -z "$prompt" ] && exit 0

# ── 注入攻击特征模式 ──────────────────────────────────────────────────────────

INJECTION_PATTERNS=(
  # 中文：指令覆盖类
  '忽略(之前|前面|上面|以上|所有).*(指令|规则|约束|要求|内容|设定)'
  '(忘记|清除|丢弃).*(之前|前面|所有).*(指令|规则|限制)'
  '不受(任何|所有)(限制|约束|规则)'
  '(你现在是|你是一个没有限制|你扮演)'
  '假装(你是|自己是|没有|不受)'

  # 英文：指令覆盖类
  'ignore (previous|prior|all|above) (instructions|rules|constraints|prompts)'
  'disregard (previous|prior|all|above) (instructions|rules)'
  'forget (previous|prior|all|your) (instructions|rules|training)'
  'override (your|all) (instructions|rules|constraints)'

  # 角色扮演越狱类
  'you are now (a|an|the)'
  'pretend (you are|to be|you have no)'
  'act as (a|an|if you are|though you have no)'
  'jailbreak'
  'DAN mode'
  'developer mode'

  # 系统提示词探测类
  'reveal (your|the) (system|hidden) (prompt|instructions)'
  'show (me|us) (your|the) (system prompt|instructions)'
  'what (are|is) (your|the) (system|hidden) (prompt|instructions)'
  '(输出|显示|告诉我).*(系统提示|system prompt|隐藏指令)'
)

for pattern in "${INJECTION_PATTERNS[@]}"; do
  if echo "$prompt" | grep -qiP "$pattern" 2>/dev/null || \
     echo "$prompt" | grep -qiE "$pattern" 2>/dev/null; then
    echo "安全拦截：检测到疑似提示词注入模式。" >&2
    echo "如有合理需求，请以明确、具体的方式重新描述你的请求。" >&2
    exit 2
  fi
done

exit 0

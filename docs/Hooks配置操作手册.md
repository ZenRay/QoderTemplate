# Qoder Hooks 配置操作手册

> Hooks 是 Qoder 的生命周期钩子机制，允许在 Agent 操作的关键节点自动触发外部脚本，实现安全拦截、代码检查、审计日志、消息通知等工程化能力。

---

## 目录

1. [工作原理](#1-工作原理)
2. [配置结构速查](#2-配置结构速查)
3. [完整事件列表](#3-完整事件列表)
4. [各事件 stdin 数据格式](#4-各事件-stdin-数据格式)
5. [matcher 语法](#5-matcher-语法)
6. [脚本退出码规范](#6-脚本退出码规范)
7. [实战配置示例](#7-实战配置示例)
8. [脚本编写模板](#8-脚本编写模板)
9. [调试技巧](#9-调试技巧)
10. [常见问题](#10-常见问题)

---

## 1. 工作原理

```
用户触发操作
     │
     ▼
[事件触发] ──► Qoder 查找匹配的 Hook 配置
                    │
                    ▼
             启动 Hook 脚本进程
             stdin ← JSON 数据
                    │
                    ▼
             脚本处理逻辑
                    │
          ┌─────────┴──────────┐
        exit 0              exit 2（可阻断事件）
        继续执行              阻断 + stderr 注入会话
```

**关键机制：**
- Hook **完全自动触发**，由 Qoder 在对应事件发生时自动调度脚本，无需手动执行
- Hook 脚本通过 **stdin** 接收 JSON 格式的上下文数据（由 Qoder 自动注入）
- 脚本通过 **exit code** 告知 Qoder 是否继续执行
- **stderr** 内容在 exit 2 时会注入到 Agent 会话上下文
- **stdout** 输出的 JSON 可用于细粒度控制（高级用法）

> 例如：点击「压缩上下文」按钮 → Qoder 自动触发 `PreCompact` 事件 → 自动执行挂载的脚本。Agent 执行命令、写入文件等操作同理，均为全自动调度。

---

## 2. 配置结构速查

```json
{
  "hooks": {
    "事件名": [
      {
        "matcher": "匹配条件（可选）",
        "hooks": [
          {
            "type": "command",
            "command": "脚本路径或 shell 命令",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Hook 对象字段：**

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | string | ✅ | — | 固定值 `"command"` |
| `command` | string | ✅ | — | 脚本路径或 shell 命令 |
| `timeout` | number | ❌ | `60` | 超时秒数，超时后强制终止 |

---

## 3. 完整事件列表

| 事件名 | 触发时机 | 可阻断 | `matcher` 匹配字段 |
|--------|----------|:------:|-------------------|
| `PreToolUse` | 工具执行**前** | ✅ | 工具名 |
| `PostToolUse` | 工具执行**成功后** | ❌ | 工具名 |
| `PostToolUseFailure` | 工具执行**失败后** | ❌ | 工具名 |
| `UserPromptSubmit` | 用户提交 prompt、Agent 处理前 | ✅ | — |
| `Stop` | Agent 完成所有响应时 | ✅ | — |
| `SessionStart` | 会话启动时 | ❌ | `startup` / `resume` / `compact` |
| `SessionEnd` | 会话结束时 | ❌ | `prompt_input_exit` / `other` |
| `SubagentStart` | 子 Agent 启动时 | ❌ | Agent 类型名 |
| `SubagentStop` | 子 Agent 完成时 | ✅ | Agent 类型名 |
| `PreCompact` | 上下文压缩前 | ❌ | `manual` / `auto` |
| `Notification` | 权限请求或任务完成通知 | ❌ | `permission` / `result` |

> ⚠️ **IDE 插件限制**：JetBrains / VS Code 插件目前仅支持 `UserPromptSubmit`、`PreToolUse`、`PostToolUse`、`PostToolUseFailure`、`Stop` 五个事件。CLI 模式支持全部事件。

---

## 4. 各事件 stdin 数据格式

所有 Hook 脚本均通过 `stdin` 接收 JSON。以下是各事件的完整字段说明。

### PreToolUse / PostToolUse

```json
{
  "session_id": "sess_abc123",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm run build"
  },
  "tool_output": "Build succeeded in 3.2s"
}
```

> `tool_output` 仅在 `PostToolUse` 中存在；`PreToolUse` 无此字段。

**常用工具的 `tool_input` 结构：**

| 工具名 | tool_input 字段 |
|--------|----------------|
| `Bash` | `{ "command": "..." }` |
| `Write` | `{ "path": "...", "content": "..." }` |
| `Edit` | `{ "path": "...", "old_string": "...", "new_string": "..." }` |
| `Read` | `{ "path": "..." }` |
| `WebFetch` | `{ "url": "..." }` |

### PostToolUseFailure

```json
{
  "session_id": "sess_abc123",
  "tool_name": "Bash",
  "tool_input": {
    "command": "docker build ."
  },
  "error": "docker: command not found"
}
```

### UserPromptSubmit

```json
{
  "session_id": "sess_abc123",
  "prompt": "请帮我重构 src/auth.ts 文件"
}
```

### Stop

```json
{
  "session_id": "sess_abc123",
  "stop_reason": "end_turn"
}
```

### SessionStart

```json
{
  "session_id": "sess_abc123",
  "source": "startup"
}
```

`source` 取值：`startup`（新会话）、`resume`（恢复会话）、`compact`（压缩后继续）

### SessionEnd

```json
{
  "session_id": "sess_abc123",
  "end_reason": "prompt_input_exit"
}
```

`end_reason` 取值：`prompt_input_exit`（用户主动退出）、`other`

### SubagentStart / SubagentStop

```json
{
  "session_id": "sess_abc123",
  "agent_type": "Bash"
}
```

### PreCompact

```json
{
  "session_id": "sess_abc123",
  "trigger": "auto"
}
```

`trigger` 取值：`manual`（手动触发）、`auto`（自动触发）

### Notification

```json
{
  "session_id": "sess_abc123",
  "type": "permission",
  "message": "Agent 请求执行 git push"
}
```

---

## 5. matcher 语法

`matcher` 用于过滤触发条件，不填则匹配所有。

| 写法 | 含义 | 示例 |
|------|------|------|
| 省略 | 匹配所有 | — |
| `"*"` | 匹配所有 | `"*"` |
| 精确字符串 | 精确匹配工具名 | `"Bash"` |
| `\|` 分隔 | 多值 OR 匹配 | `"Write\|Edit"` |
| 正则表达式 | 正则匹配 | `"mcp__.*"` |

**PreToolUse/PostToolUse 中常用 matcher 值：**

```
Bash        Write       Edit
Read        WebFetch    TodoWrite
```

**SessionStart 中的 matcher：**

```
startup     resume      compact
```

---

## 6. 脚本退出码规范

| 退出码 | 效果 | 适用场景 |
|--------|------|----------|
| `0` | **放行**，继续执行 | 正常通过检查 |
| `2` | **阻断**（仅可阻断事件有效），stderr 注入会话 | 拦截危险操作 |
| 其他（1/3/...） | **非阻断性错误**，stderr 展示给用户，执行继续 | 警告但不中断 |

**阻断流程说明（exit 2）：**

```bash
echo "原因说明写入 stderr，会注入到 Agent 会话" >&2
exit 2
```

Agent 收到阻断后，会将 stderr 内容作为上下文，自动调整策略重试或告知用户。

---

## 7. 实战配置示例

### 场景一：高危命令安全门（PreToolUse）

```json
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/security-gate.sh", "timeout": 10 }
    ]
  }
]
```

### 场景二：写入后自动 Lint（PostToolUse）

```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/auto-lint.sh", "timeout": 30 }
    ]
  }
]
```

### 场景三：失败操作日志记录（PostToolUseFailure）

```json
"PostToolUseFailure": [
  {
    "matcher": "*",
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/log-failure.sh" }
    ]
  }
]
```

### 场景四：Prompt 关键词过滤（UserPromptSubmit）

```json
"UserPromptSubmit": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/prompt-guard.sh", "timeout": 5 }
    ]
  }
]
```

```bash
#!/bin/bash
# prompt-guard.sh
input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')

if echo "$prompt" | grep -qiE '忽略之前的指令|ignore previous instructions|system prompt'; then
  echo "检测到潜在的提示词注入攻击，已拦截。" >&2
  exit 2
fi
exit 0
```

### 场景五：任务完成桌面通知（Stop）

```json
"Stop": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/notify-done.sh" }
    ]
  }
]
```

```bash
#!/bin/bash
# notify-done.sh (macOS)
osascript -e 'display notification "Agent 任务已完成" with title "Qoder"' 2>/dev/null
exit 0
```

### 场景六：会话启动时打印环境信息（SessionStart）

```json
"SessionStart": [
  {
    "matcher": "startup",
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/session-init.sh" }
    ]
  }
]
```

```bash
#!/bin/bash
# session-init.sh
echo "=== 会话初始化 ===" >&2
echo "Node: $(node -v 2>/dev/null || echo 未安装)" >&2
echo "Python: $(python3 --version 2>/dev/null || echo 未安装)" >&2
echo "Git branch: $(git branch --show-current 2>/dev/null || echo 未知)" >&2
exit 0
```

### 场景七：子 Agent 审计日志（SubagentStop）

```json
"SubagentStop": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/audit-subagent.sh" }
    ]
  }
]
```

```bash
#!/bin/bash
# audit-subagent.sh
input=$(cat)
agent=$(echo "$input" | jq -r '.agent_type // "unknown"')
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SubAgent 完成: $agent" >> .qoderwork/logs/subagent-audit.log
exit 0
```

### 场景八：多事件组合配置（完整示例）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": ".qoderwork/hooks/security-gate.sh", "timeout": 10 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": ".qoderwork/hooks/auto-lint.sh", "timeout": 30 }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": ".qoderwork/hooks/log-failure.sh" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": ".qoderwork/hooks/prompt-guard.sh", "timeout": 5 }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": ".qoderwork/hooks/notify-done.sh" }
        ]
      }
    ]
  }
}
```

---

## 8. 脚本编写模板

### 通用安全模板（PreToolUse 拦截型）

```bash
#!/bin/bash
# hooks/my-gate.sh
# 用途：PreToolUse 拦截脚本模板
# 退出码: 0=放行, 2=阻断

set -uo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // "unknown"')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# 无命令则放行
[ -z "$command" ] && exit 0

# 自定义拦截逻辑
if echo "$command" | grep -qE '你的危险模式'; then
  echo "拦截原因: 命令 [$command] 命中安全规则。" >&2
  exit 2
fi

exit 0
```

### 通用记录模板（PostToolUse 审计型）

```bash
#!/bin/bash
# hooks/my-logger.sh
# 用途：PostToolUse 日志记录模板
# 退出码: 始终 0（非阻断）

set -uo pipefail

LOG_DIR=".qoderwork/logs"
mkdir -p "$LOG_DIR"

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // "unknown"')
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# 记录日志
echo "[$timestamp] $tool" >> "$LOG_DIR/audit.log"

exit 0
```

### 通用文件处理模板（PostToolUse 文件操作型）

```bash
#!/bin/bash
# hooks/my-file-handler.sh
# 用途：Write/Edit 后处理文件

set -uo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.path // empty')

# 文件不存在则跳过
[ -z "$file" ] || [ ! -f "$file" ] && exit 0

# 对文件进行处理
case "$file" in
  *.your_ext)
    your_tool "$file" 2>&1 || true
    ;;
esac

exit 0
```

---

## 9. 调试技巧

### 手动模拟测试（推荐）

不需要启动 Qoder，直接在终端模拟 stdin 输入：

```bash
# 测试 PreToolUse（Bash 工具）
echo '{"session_id":"test","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | bash .qoderwork/hooks/security-gate.sh
echo "exit: $?"

# 测试 PostToolUse（Write 工具）
echo '{"session_id":"test","tool_name":"Write","tool_input":{"path":"./src/index.ts"}}' \
  | bash .qoderwork/hooks/auto-lint.sh
echo "exit: $?"

# 测试 PostToolUseFailure
echo '{"session_id":"test","tool_name":"Bash","error":"permission denied"}' \
  | bash .qoderwork/hooks/log-failure.sh
echo "exit: $?"
```

### 检查 jq 解析是否正确

```bash
# 验证字段提取逻辑
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  | jq -r '.tool_input.command'
# 输出: ls -la
```

### 开启脚本调试输出

在脚本开头临时加入 `set -x` 查看执行过程：

```bash
#!/bin/bash
set -x  # 调试时启用，上线前移除
input=$(cat)
...
```

### 查看运行日志

```bash
# 实时监控失败日志
tail -f .qoderwork/logs/failure.log
```

---

## 10. 常见问题

### Q1: 脚本不执行，怎么排查？

**检查项：**
1. 脚本是否有执行权限：`ls -la .qoderwork/hooks/`
2. 赋予执行权限：`chmod +x .qoderwork/hooks/*.sh`
3. 检查 `setting.json` 中事件名拼写是否正确（区分大小写）
4. 检查 `command` 路径是否相对于项目根目录

### Q2: exit 2 没有阻断执行？

**可能原因：**
- 事件本身不可阻断（如 `PostToolUse`、`PostToolUseFailure` 均不可阻断）
- 仅 `PreToolUse`、`UserPromptSubmit`、`Stop`、`SubagentStop` 支持 exit 2 阻断

### Q3: stderr 内容没有出现在会话中？

**检查：**
- 确认使用的是 exit 2（不是 exit 1）
- 确认内容写入的是 `>&2`（stderr），不是 stdout

### Q4: 脚本超时了怎么办？

默认超时 60 秒。调小 `timeout` 值可避免阻塞会话：

```json
{ "type": "command", "command": "your-script.sh", "timeout": 10 }
```

### Q5: 同一事件能挂载多个 Hook 吗？

可以，`hooks` 数组中可以有多个条目，**按顺序串行执行**：

```json
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/security-gate.sh" },
      { "type": "command", "command": ".qoderwork/hooks/audit-bash.sh" }
    ]
  }
]
```

### Q6: 不同 matcher 的 Hook 同时命中怎么处理？

同一事件下，多个 matcher 均命中时，**全部按顺序执行**，任意一个返回 exit 2 均可阻断（对可阻断事件）。

### Q7: setting.json 改动何时生效？

**立即生效**，无需重启。Qoder 每次触发事件时重新读取配置。

---

*参考版本：Qoder Harness Engineering V0.1 | 最后更新：2026-04-30*

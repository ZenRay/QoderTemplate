# Qoder Harness Engineering 落地示例

> **定位**：本文档是 Qoder 项目工程化接入的完整落地参考，涵盖配置规范、Hooks 工程、权限策略与最佳实践，适合作为团队新项目的通用范式。

---

## 目录

1. [配置层级与优先级](#1-配置层级与优先级)
2. [项目目录结构](#2-项目目录结构)
3. [用户级配置说明](#3-用户级配置说明)
4. [项目级配置 — setting.json](#4-项目级配置--settingjson)
5. [本地私有配置 — setting.local.json](#5-本地私有配置--settinglocaljson)
6. [Permissions 权限策略](#6-permissions-权限策略)
7. [Hooks 生命周期工程](#7-hooks-生命周期工程)
8. [AGENTS.md — Agent 行为约束](#8-agentsmd--agent-行为约束)
9. [扩展配置方案](#9-扩展配置方案)
10. [快速启动指南](#10-快速启动指南)

---

## 1. 配置层级与优先级

Qoder 采用三层配置合并机制，优先级从低到高：

```
~/.qoder/settings.json          ← 用户级（全局，对所有项目生效）
  ↓ 合并
{project}/.qoder/setting.json   ← 项目级（提交 Git，团队共享）
  ↓ 合并
{project}/.qoder/setting.local.json ← 本地级（不提交，个人覆盖）
```

**关键原则：**
- 低优先级配置不会被覆盖，而是**合并叠加**
- `deny` 规则优先于 `allow`，无论在哪一层定义
- 建议将 `setting.local.json` 加入 `.gitignore`

---

## 2. 项目目录结构

```
{project}/
├── .qoder/
│   ├── agents/                 # 自定义子 Agent（.md 格式）
│   ├── commands/               # 自定义斜杠命令
│   ├── skills/                 # 自定义技能（Skill）
│   ├── setting.json            # 项目级配置（Git 共享）
│   └── setting.local.json      # 本地私有覆盖（加入 .gitignore）
├── .qoderwork/
│   └── hooks/                  # 生命周期钩子脚本
│       ├── security-gate.sh    # 高危命令拦截
│       ├── auto-lint.sh        # 写入后自动 Lint
│       └── log-failure.sh      # 失败日志记录
├── AGENTS.md                   # Agent 行为指令（项目上下文）
└── QoderHarnessEngineering落地示例.md   # 本文档
```

---

## 3. 用户级配置说明

> **本项目不修改用户级配置。** 用户级配置属于个人全局设置，由开发者自行维护。

**用户级配置文件路径：**
```
~/.qoder/settings.json
```

**典型用途：**
- 设置个人偏好的默认权限（如允许特定工具无需确认）
- 配置全局 Hooks（如所有项目统一的通知脚本）
- 设置个人 API 访问白名单

**示例（用户级配置参考）：**
```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(ls*)",
      "Read(~/Documents/**)"
    ],
    "deny": [
      "Bash(sudo rm*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)"
    ]
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "~/.qoder/hooks/notify-done.sh" }
        ]
      }
    ]
  }
}
```

**与项目级配置的关系：**

| 层级 | 文件 | 谁维护 | 是否提交 Git |
|------|------|--------|------------|
| 用户级 | `~/.qoder/settings.json` | 开发者个人 | 否 |
| 项目级 | `.qoder/setting.json` | 项目团队 | 是 |
| 本地级 | `.qoder/setting.local.json` | 开发者个人 | 否 |

---

## 4. 项目级配置 — setting.json

本项目 `setting.json` 完整内容如下：

```json
{
  "permissions": {
    "allow": [
      "Read(./**)",
      "Edit(./src/**)",
      "Edit(./tests/**)",
      "Bash(npm run*)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(grep*)",
      "Bash(ls*)",
      "WebFetch(domain:api.github.com)"
    ],
    "ask": [
      "Bash(git commit*)",
      "Bash(git push*)",
      "Edit(./.qoder/**)",
      "Edit(./.qoderwork/**)"
    ],
    "deny": [
      "Bash(rm*)",
      "Bash(chmod*)",
      "Bash(sudo*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.config/**)"
    ]
  },
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
          { "type": "command", "command": ".qoderwork/hooks/log-failure.sh", "timeout": 10 }
        ]
      }
    ]
  }
}
```

**设计要点：**
- `allow` 放行常规只读和受控编辑操作
- `ask` 拦截 Git 写操作和配置文件修改，强制人工确认
- `deny` 硬性禁止危险命令和敏感路径访问
- 三个 Hooks 分别覆盖执行前拦截、执行后检查、失败记录三个场景

---

## 5. 本地私有配置 — setting.local.json

`setting.local.json` 用于开发者在不影响团队的前提下做本地覆盖，**必须加入 `.gitignore`**。

本项目提供的初始模板：
```json
{
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  }
}
```

**常见本地覆盖场景示例：**
```json
{
  "permissions": {
    "allow": [
      "Edit(./**)",
      "Bash(python*)",
      "Bash(pip*)"
    ]
  }
}
```

---

## 6. Permissions 权限策略

### 规则格式速查表

| 类型 | 格式 | 示例 |
|------|------|------|
| Bash 命令 | `Bash(前缀*)` | `Bash(npm run*)` |
| 读取文件 | `Read(glob)` | `Read(./src/**)` |
| 编辑文件 | `Edit(glob)` | `Edit(./tests/**)` |
| 网络请求 | `WebFetch(domain:域名)` | `WebFetch(domain:api.github.com)` |
| 路径取反 | `Read(!路径)` | `Read(!~/.ssh/**)` |

### 三级策略语义

```
allow  →  自动放行，无提示
ask    →  弹出确认对话框，用户决定是否执行
deny   →  直接拒绝，不可执行，不弹窗
```

### 优先级规则

当同一规则同时出现在多个级别时：
1. `deny` 优先于 `allow` 和 `ask`
2. 更具体的规则优先于通配符规则
3. 本地级覆盖项目级，项目级覆盖用户级

---

## 7. Hooks 生命周期工程

### 完整事件列表

| 事件 | 触发时机 | 可阻断 | matcher 匹配对象 |
|------|----------|--------|----------------|
| `PreToolUse` | 工具执行前 | ✅ exit 2 | 工具名（Bash/Write/Edit/...） |
| `PostToolUse` | 工具成功后 | ❌ | 工具名 |
| `PostToolUseFailure` | 工具失败后 | ❌ | 工具名 |
| `UserPromptSubmit` | 用户提交 prompt 后 | ✅ | — |
| `Stop` | Agent 完成响应时 | ✅ | — |
| `SessionStart` | 会话启动 | ❌ | startup/resume/compact |
| `SessionEnd` | 会话结束 | ❌ | prompt_input_exit/other |
| `SubagentStart` | 子 Agent 启动 | ❌ | Agent 类型名 |
| `SubagentStop` | 子 Agent 完成 | ✅ | Agent 类型名 |
| `PreCompact` | 上下文压缩前 | ❌ | manual/auto |
| `Notification` | 权限/通知事件 | ❌ | permission/result |

### 脚本退出码规范

| 退出码 | 效果 |
|--------|------|
| `0` | 允许继续执行 |
| `2` | **阻断**（仅对可阻断事件有效，stderr 注入会话） |
| 其他 | 非阻断性错误，stderr 展示给用户，执行继续 |

### 本项目三个 Hooks 说明

#### security-gate.sh（`PreToolUse` / Bash）

拦截以下高危模式，退出码 2 直接阻断：

| 拦截模式 | 说明 |
|----------|------|
| `rm -rf` / `rm --recursive` | 递归删除 |
| `DROP TABLE` / `DROP DATABASE` | 数据库破坏性操作 |
| `TRUNCATE TABLE` | 清空数据表 |
| `dd if=` | 磁盘写入操作 |
| `mkfs.` | 格式化磁盘 |
| `chmod -R 777` | 危险权限开放 |
| `sudo rm` | 特权删除 |
| `:(){:|:&};:` | Fork Bomb |

#### auto-lint.sh（`PostToolUse` / Write\|Edit）

根据文件类型自动选择 Lint 工具：

| 文件类型 | 工具 | 行为 |
|----------|------|------|
| `.js/.ts/.jsx/.tsx` | ESLint | `--fix --quiet` |
| `.py` | ruff（优先）/ flake8 | `--fix --quiet` |
| `.go` | gofmt | `-w` 格式化 |
| `.sh` | shellcheck | 静态检查 |

#### log-failure.sh（`PostToolUseFailure` / \*）

将失败记录追加到 `.qoderwork/logs/failure.log`：
```
[2026-04-30 15:32:01] FAILURE | tool=Bash | error=command not found: docker
```

---

## 8. AGENTS.md — Agent 行为约束

`AGENTS.md` 位于项目根目录，为 Qoder 提供项目上下文和行为规范。每次会话自动加载。

**推荐写入的内容：**
- 项目简介和技术栈
- 代码修改范围约束
- Git 操作规范
- 禁止行为清单
- Hooks 脚本速查

本项目 `AGENTS.md` 定义了以下约束：
- 修改配置文件前须用户确认
- 禁止直接删除文件
- Git commit/push 前须用户确认
- 代码编辑范围限定在 `./src/**` 和 `./tests/**`

---

## 9. 扩展配置方案

### 方案 A：添加 Prompt 注入防护

在 `UserPromptSubmit` 中过滤危险指令模板（防止提示词注入攻击）：

```json
"UserPromptSubmit": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/prompt-guard.sh", "timeout": 5 }
    ]
  }
]
```

### 方案 B：任务完成桌面通知（macOS）

```json
"Stop": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/notify-done.sh" }
    ]
  }
]
```

`notify-done.sh`：
```bash
#!/bin/bash
osascript -e 'display notification "Qoder 任务已完成" with title "Qoder"'
exit 0
```

### 方案 C：子 Agent 审计日志

```json
"SubagentStop": [
  {
    "hooks": [
      { "type": "command", "command": ".qoderwork/hooks/audit-subagent.sh" }
    ]
  }
]
```

### 方案 D：精细化 WebFetch 域名白名单

```json
"permissions": {
  "allow": [
    "WebFetch(domain:api.github.com)",
    "WebFetch(domain:registry.npmjs.org)",
    "WebFetch(domain:docs.qoder.com)"
  ],
  "deny": [
    "WebFetch(domain:*)"
  ]
}
```

> **注意**：`deny` 的通配 `WebFetch(domain:*)` 配合 `allow` 白名单，可实现"仅允许指定域名"的网络访问控制。

---

## 10. 快速启动指南

将本项目作为新项目范式使用时，按以下步骤操作：

### Step 1 — 复制模板

```bash
cp -r .qoder/ /path/to/new-project/.qoder/
cp -r .qoderwork/ /path/to/new-project/.qoderwork/
cp AGENTS.md /path/to/new-project/AGENTS.md
```

### Step 2 — 配置 .gitignore

在新项目的 `.gitignore` 中添加：

```
.qoder/setting.local.json
.qoderwork/logs/
```

### Step 3 — 按项目需求调整权限

编辑 `.qoder/setting.json`，根据项目技术栈调整 `allow` 规则：

```json
"allow": [
  "Bash(python*)",
  "Bash(pip*)",
  "Bash(pytest*)"
]
```

### Step 4 — 更新 AGENTS.md

在 `AGENTS.md` 中填写项目实际的：
- 技术栈和框架说明
- 代码目录结构
- 特定的禁止行为

### Step 5 — 赋予脚本执行权限

```bash
chmod +x .qoderwork/hooks/*.sh
```

### Step 6 — 验证配置

打开 Qoder，执行一条被 `ask` 规则覆盖的命令（如 `git commit`），确认提示框正常弹出即表示配置生效。

---

*文档生成时间：2026-04-30 | 基于 Qoder 配置规范整理*

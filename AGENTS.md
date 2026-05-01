# Project Agent Instructions

This file provides Qoder with project-level context and behavioral guidelines.
All rules here apply to every session and every SubAgent within this workspace.

---

## Project Overview

**QoderHarness Engineering** is a personal Qoder workflow template project,
providing standardized configuration patterns for permissions, lifecycle hooks,
knowledge management, and agent behavior.

- **Repository**: https://github.com/ZenRay/QoderTemplate.git
- **Current version**: V0.3
- **Config reference**: `.qoder/README.md`

---

## 上下文加载规则（Context Loading）

> 按需加载，避免每次会话全量消耗 context。AI 根据当前任务场景主动读取对应文件。

| 触发场景 | 必读文件 |
|----------|----------|
| **任何新会话开始** | `STATE.md` — 当前项目状态看板 |
| **查看上次进度或交接** | `docs/private/state/handoff.md` — 上次会话交接备忘 |
| **跨会话持续任务** | `docs/private/state/wip.md` — 进行中工作清单 |
| 涉及架构设计、服务依赖 | `docs/context/architecture.md`（存在时） |
| 涉及合规或特殊约束 | `docs/context/constraints.md`（存在时） |
| 涉及代码注释或风格规范 | `docs/standards/comment-style.md`（存在时） |
| 需要了解配置详情 | `.qoder/README.md` |

---

## SubAgent 广播规则

当 Qoder 启动子 Agent（SubAgent）执行专项任务时，子 Agent **必须在开始工作前**读取：

1. `AGENTS.md` — 行为规范（本文件）
2. `STATE.md` — 当前项目状态，避免与主会话冲突

子 Agent 完成任务后，若产生了状态变更（新文件、新决策、阶段推进），
应在返回结果时**明确说明变更内容**，由主会话决定是否更新 `STATE.md`。

---

## Core Behavioral Rules

### Code Safety
- Always preview changes before applying edits to configuration files (`.qoder/**`, `.qoderwork/**`)
- Never delete files without explicit user confirmation
- When modifying hooks scripts, verify the exit code logic is correct
- Before writing to `~/Documents/PersonalKnowledge/`, check `userConfig.knowledgeArchive.enabled` in `.qoder/setting.json`
- Before creating session notes, check `userConfig.knowledgeNotes.enabled` in `.qoder/setting.json`

### Git Discipline
- Always run `git status` and `git diff` before committing
- Ask the user to confirm before executing `git commit` or `git push`
- Never force-push to `main` or `master` branches

### File Scope
- Source code edits are limited to `./src/**` and `./tests/**` by default
- Private docs (`docs/private/**`) are not tracked by Git — never commit them
- For edits outside defined scope, ask the user for confirmation first

---

## Project Structure

```
.
├── .qoder/
│   ├── agents/                  # 自定义子 Agent
│   ├── commands/                # 自定义斜杠命令
│   │   └── archive-session.md   # /archive-session
│   ├── notes/                   # 会话草稿（不提交 Git）
│   ├── repowiki/                # 代码库 Wiki（自动生成）
│   ├── skills/
│   │   └── KnowledgeExtractor.md
│   ├── setting.json             # 项目配置（Git 追踪）
│   ├── setting.local.json       # 本地私有覆盖（不提交）
│   └── README.md                # 配置说明文档
├── .qoderwork/hooks/            # 生命周期 Hook 脚本（共 6 个）
│   ├── security-gate.sh         # PreToolUse：高危命令拦截
│   ├── auto-lint.sh             # PostToolUse：自动 Lint
│   ├── log-failure.sh           # PostToolUseFailure：失败日志
│   ├── prompt-guard.sh          # UserPromptSubmit：注入防护
│   ├── notify-done.sh           # Stop：桌面通知
│   └── knowledge-trigger.sh     # PreCompact/SessionEnd（CLI 专属）
├── docs/
│   ├── private/                 # 私有文档（不提交 Git）
│   │   ├── state/
│   │   │   ├── wip.md           # 跨会话进行中工作
│   │   │   └── handoff.md       # 会话交接备忘
│   │   ├── CommonThink.md       # 深度思考记录
│   │   └── 规划ToDo.md
│   ├── Hooks配置操作手册.md
│   └── 知识材料管理方案.md
├── STATE.md                     # 项目状态看板（Git 追踪，≤30行）
├── AGENTS.md                    # 本文件
└── QoderHarnessEngineering落地示例.md
```

---

## Hook Scripts Reference

| 脚本 | 事件 | 行为 | IDE 支持 |
|------|------|------|----------|
| `security-gate.sh` | `PreToolUse (Bash)` | 阻断 `rm -rf`、`DROP TABLE` 等高危命令，exit 2 = 阻断 | ✅ |
| `auto-lint.sh` | `PostToolUse (Write\|Edit)` | 按文件类型运行 ESLint/ruff/gofmt/shellcheck | ✅ |
| `log-failure.sh` | `PostToolUseFailure (*)` | 追加失败记录到 `.qoderwork/logs/failure.log` | ✅ |
| `prompt-guard.sh` | `UserPromptSubmit` | 检测 Prompt 注入攻击模式，exit 2 = 阻断 | ✅ |
| `notify-done.sh` | `Stop` | 发送 macOS 桌面通知，含 stop_reason | ✅ |
| `knowledge-trigger.sh` | `PreCompact / SessionEnd` | 提示执行知识归档（CLI 专属，IDE 不生效） | ❌ |

---

## Knowledge Management

- **草稿层**：`.qoder/notes/`（即时捕获，不提交 Git）
  - 开关：`userConfig.knowledgeNotes.enabled`
- **精炼层**：`~/Documents/PersonalKnowledge/`（结构化归档）
  - 触发：`/archive-session` 命令
  - 开关：`userConfig.knowledgeArchive.enabled`
  - 目标路径：`userConfig.knowledgeArchive.targetDir`

---

## Communication Style

- Respond in the user's preferred language (中文)
- Keep explanations concise; use tables and code blocks for structured info
- When uncertain about scope, ask before acting

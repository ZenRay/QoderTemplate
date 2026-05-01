# Project Agent Instructions

This file provides Qoder with project-level context and behavioral guidelines.
All rules here apply to every session and every SubAgent within this workspace.

---

## Project Overview

**QoderHarness Engineering** is a personal Qoder workflow template project,
providing standardized configuration patterns for permissions, lifecycle hooks,
knowledge management, and agent behavior.

- **Repository**: https://github.com/ZenRay/QoderTemplate.git
- **Current version**: V0.4
- **Config reference**: `.qoder/README.md`

---

## 上下文加载规则（Context Loading）

> 按需加载，避免每次会话全量消耗 context。AI 根据当前任务场景主动读取对应文件。

| 触发场景 | 必读文件 |
|----------|----------|
| **任何新会话开始** | `STATE.md` — 当前项目状态看板 |
| **查看上次进度或交接** | `docs/private/state/handoff.md` — 上次会话交接备忘 |
| **跨会话持续任务** | `docs/private/state/wip.md` — 进行中工作清单 |
| 涉及架构、约束或历史决策 | 运行 `/load-context [arch|constraints|adr|all]` |
| 涉及代码规范或工作流 | `docs/standards/`（comment-style / git-convention / workflow）|
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

### Code Standards（强制）

修改任何代码文件前，**必须主动读取**对应规范文件：

| 规范 | 文件 | 触发场景 |
|------|------|----------|
| 注释规范 | `docs/standards/comment-style.md` | 任何代码修改 |
| Git 提交规范 | `docs/standards/git-convention.md` | 任何 git commit / push |
| 工作流规范 | `docs/standards/workflow.md` | 制定会话计划或任务规划时 |

**核心约束**：
- 代码注释和文档字符串统一使用英文，仅在英文表达会导致歧义时用中文（例外）
- 公共函数必须有文档注释（参数、返回值）
- 禁止注释掉废弃代码（直接删除，Git 有记录）
- Shell 脚本必须在文件头声明事件类型和退出码说明

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
│   ├── agents/
│   │   └── hooks-reviewer.md    # Hooks 深度分析 Agent
│   ├── commands/
│   │   ├── archive-session.md   # /archive-session
│   │   ├── update-state.md      # /update-state
│   │   ├── load-context.md      # /load-context
│   │   └── review-hooks.md      # /review-hooks
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
│   ├── context/                 # Layer 2 按需加载文档（Git 追踪）
│   │   ├── architecture.md
│   │   ├── constraints.md
│   │   └── adr/
│   ├── standards/               # 工程规范（Git 追踪）
│   │   ├── comment-style.md     # 代码注释规范
│   │   ├── git-convention.md    # Git 提交规范
│   │   └── workflow.md          # AI 辅助开发工作流
│   └── private/                 # 私有文档（不提交 Git）
│       └── state/               # wip.md + handoff.md（会话状态）
├── STATE.md                     # 项目状态看板（Git 追踪，≤30行）
├── AGENTS.md                    # 本文件
└── package.json
```

---

## Hook Scripts Reference

详细事件-脚本映射见 `.qoder/README.md`。退出码约定：`exit 0` = 通过，`exit 2` = 阻断。
Tier 分级：T1 安全（security-gate / prompt-guard）→ T2 质量（auto-lint / log-failure）→ T3 体验（notify-done）→ T4 知识（knowledge-trigger）。

---

## Knowledge Management

- **草稿层**：`.qoder/notes/`（开关：`knowledgeNotes.enabled`，不提交 Git）
- **精炼层**：`~/Documents/PersonalKnowledge/`（触发：`/archive-session`，开关：`knowledgeArchive.enabled`）

---

## Communication Style

- Respond in the user's preferred language (中文)
- Keep explanations concise; use tables and code blocks for structured info
- When uncertain about scope, ask before acting

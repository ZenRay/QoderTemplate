# 项目配置说明

本文档覆盖 QoderHarness 工程范式的三个核心配置目录：`.qoder/`（Qoder 配置中心）、`.qoderwork/`（Hooks 脚本）、`docs/`（工程文档）。

---

## 整体目录结构

```
.
├── .qoder/
│   ├── agents/
│   │   └── hooks-reviewer.md        # /review-hooks 触发的专职 Agent
│   ├── commands/
│   │   ├── archive-session.md       # /archive-session
│   │   ├── load-context.md          # /load-context
│   │   ├── paradigm-adopt.md        # /paradigm-adopt
│   │   ├── paradigm-init.md         # /paradigm-init
│   │   ├── paradigm-sync.md         # /paradigm-sync
│   │   ├── review-hooks.md          # /review-hooks
│   │   └── update-state.md          # /update-state
│   ├── notes/                       # 会话草稿（私有，不提交 Git）
│   │   └── .gitkeep
│   ├── repowiki/                    # Qoder 自动生成的代码库 Wiki（勿手动编辑）
│   ├── skills/
│   │   └── KnowledgeExtractor.md   # 7 步知识归档技能
│   ├── setting.json                 # 项目级配置（Git 追踪）
│   ├── setting.local.json           # 本地私有覆盖（不提交 Git）
│   └── README.md                    # 本文件
├── .qoderwork/
│   ├── hooks/
│   │   ├── auto-lint.sh             # PostToolUse：自动 Lint（T2）
│   │   ├── knowledge-trigger.sh     # PreCompact/SessionEnd：归档提示（T4，CLI 专属）
│   │   ├── log-failure.sh           # PostToolUseFailure：失败日志（T2）
│   │   ├── notify-done.sh           # Stop：桌面通知（T3）
│   │   ├── prompt-guard.sh          # UserPromptSubmit：注入防护（T1）
│   │   └── security-gate.sh         # PreToolUse：高危命令拦截（T1）
│   └── logs/                        # 运行日志（不提交 Git）
│       └── failure.log              # log-failure.sh 写入
└── docs/
    ├── agent-guides/                # Agent 使用指南（预留，暂空）
    ├── context/                     # Layer 2 按需加载文档（Git 追踪）
    │   ├── adr/
    │   │   └── 001-*.md             # 架构决策记录（ADR）
    │   ├── architecture.md          # 项目背景与定位（业务现状、问题域、关键架构决策）
    │   └── constraints.md           # 项目约束与边界
    ├── private/                     # 私有文档（不提交 Git）
    │   ├── state/
    │   │   ├── handoff.md           # 会话交接备忘
    │   │   └── wip.md               # 跨会话进行中工作
    │   └── *.md                     # 个人笔记、操作手册等
    └── standards/                   # 工程规范（Git 追踪）
        ├── comment-style.md         # 代码注释规范
        ├── git-convention.md        # Git 提交规范
        ├── migration-guide.md       # 范式迁移指南（绿地/棕地）
        └── workflow.md              # AI 辅助开发工作流
```

---

## .qoder/ — Qoder 配置中心

### setting.json 配置说明

#### permissions — 权限策略

控制 AI 可执行的操作范围，分三级：

| 字段 | 说明 |
|------|------|
| `allow` | 无需确认直接执行 |
| `ask` | 执行前弹窗请求用户确认 |
| `deny` | 永久拒绝，不可绕过 |

**当前 allow 关键规则：**

| 规则 | 用途 |
|------|------|
| `Read(./**)` | 读取项目所有文件 |
| `Edit(./src/**)` | 编辑源码（限定范围）|
| `Bash(git status/diff/log*)` | 只读 Git 操作 |
| `Read/Write(~/Documents/PersonalKnowledge/**)` | 知识归档目录读写 |
| `Bash(mkdir -p ~/Documents/PersonalKnowledge/**)` | 归档目录自动创建 |

**当前 ask 规则（需确认）：**
- `git commit*` / `git push*`
- 编辑 `.qoder/**` 和 `.qoderwork/**`

**当前 deny 规则（永久拒绝）：**
- `rm*` / `chmod*` / `sudo*`
- 读取 `~/.ssh/**` / `~/.aws/**` / `~/.config/**`

---

#### hooks — 生命周期钩子映射

> ⚠️ **IDE 插件限制**：仅支持 5 个事件。`PreCompact` 和 `SessionEnd` 为 CLI 专属，IDE 中不生效。

| 事件 | 脚本 | Tier | 行为 |
|------|------|------|------|
| `UserPromptSubmit` | `prompt-guard.sh` | T1 | 拦截 Prompt 注入攻击模式 |
| `PreToolUse (Bash)` | `security-gate.sh` | T1 | 阻断高危命令（rm -rf、DROP TABLE 等） |
| `PostToolUse (Write\|Edit)` | `auto-lint.sh` | T2 | 自动运行对应语言 Lint |
| `PostToolUseFailure (*)` | `log-failure.sh` | T2 | 记录失败日志到 `.qoderwork/logs/failure.log` |
| `Stop` | `notify-done.sh` | T3 | 发送 macOS 桌面通知，消息含 stop_reason |
| `PreCompact` *(CLI 专属)* | `knowledge-trigger.sh` | T4 | 提示执行知识归档 |
| `SessionEnd` *(CLI 专属)* | `knowledge-trigger.sh` | T4 | 会话退出时提示归档 |

Tier 分级：T1 安全 → T2 质量 → T3 体验 → T4 知识

---

#### userConfig — 用户自定义配置

##### `paradigmTemplateVersion` — 范式模板版本

```json
"paradigmTemplateVersion": "V0.9"
```

记录本项目最后执行 `/paradigm-init` 或 `/paradigm-sync` 时使用的模板版本。
影响命令：`/paradigm-sync`（Phase 2-A 版本比对的基准）

##### `knowledgeArchive` — 归档写入开关

```json
"knowledgeArchive": {
  "enabled": true,
  "targetDir": "~/Documents/PersonalKnowledge"
}
```

`enabled: true` = 写入文件；`false` = 仅生成预览。影响命令：`/archive-session`

##### `knowledgeNotes` — 草稿笔记开关

```json
"knowledgeNotes": {
  "enabled": true,
  "notesDir": ".qoder/notes"
}
```

`enabled: true` = 允许 AI 主动创建草稿；`false` = 不创建。影响：AI 会话中整理草稿时检查此开关。

---

### commands — 斜杠命令

在对话框输入 `/命令名` 触发，Qoder 自动注入命令文件内容为 Prompt。

| 命令 | 文件 | 用途 |
|------|------|------|
| `/archive-session` | `commands/archive-session.md` | 提炼本次会话内容，归档至 PersonalKnowledge |
| `/update-state` | `commands/update-state.md` | 更新项目状态三件套（STATE.md / wip.md / handoff.md）|
| `/load-context` | `commands/load-context.md` | 按需加载 `docs/context/` 下的架构文档 |
| `/review-hooks` | `commands/review-hooks.md` | 触发 hooks-reviewer Agent 对 Hooks 做深度分析 |
| `/paradigm-init` | `commands/paradigm-init.md` | 绿地新项目初始化（1 轮问答 + 7 步自动）|
| `/paradigm-adopt` | `commands/paradigm-adopt.md` | 棕地老项目渐进式采纳范式（分模块审计 + 确认）|
| `/paradigm-sync` | `commands/paradigm-sync.md` | 已采纳项目跟进模板升级（分级报告 + 选择应用）|

**`/load-context` 参数说明：**

| 参数 | 加载内容 |
|------|----------|
| 无参数 | `architecture.md` + `constraints.md` |
| `arch` | 仅 `docs/context/architecture.md` |
| `constraints` | 仅 `docs/context/constraints.md` |
| `adr` | `docs/context/adr/` 下所有 ADR |
| `adr-NNN` | 指定编号 ADR，如 `adr-001` |
| `all` | 全部 `docs/context/` 文档 |

---

### skills — 技能

| 技能 | 文件 | 用途 |
|------|------|------|
| KnowledgeExtractor | `skills/KnowledgeExtractor.md` | 7 步归档流程：分析会话 → 生成文件 → 更新索引 |

---

### notes — 会话草稿

- 存放会话中的临时想法、速记、踩坑记录
- **不提交 Git**（`.gitignore` 已排除 `notes/*`，仅保留 `.gitkeep`）
- 草稿质量达标后，通过 `/archive-session` 提炼到 PersonalKnowledge

---

## .qoderwork/ — Hooks 脚本

### hooks/ 脚本说明

所有脚本遵循统一约定：**`exit 0` = 通过，`exit 2` = 阻断工具执行**。

| 脚本 | 触发事件 | Tier | 核心逻辑 |
|------|---------|------|---------|
| `security-gate.sh` | `PreToolUse (Bash)` | T1 | 正则匹配高危命令（rm -rf / DROP / curl pipe 等），匹配则 exit 2 |
| `prompt-guard.sh` | `UserPromptSubmit` | T1 | 检测 Prompt 注入关键词，匹配则 exit 2 |
| `auto-lint.sh` | `PostToolUse (Write\|Edit)` | T2 | 按文件扩展名选择 Linter（Python/JS/TS/Go/Rust/Shell/MD）|
| `log-failure.sh` | `PostToolUseFailure (*)` | T2 | 追加错误信息到 `.qoderwork/logs/failure.log` |
| `notify-done.sh` | `Stop` | T3 | `osascript` 发送 macOS 系统通知 |
| `knowledge-trigger.sh` | `PreCompact` / `SessionEnd` | T4 | 输出归档提示（CLI 专属，IDE 不生效）|

### logs/

- `failure.log`：由 `log-failure.sh` 追加写入，记录每次工具失败的时间戳、工具名、错误信息
- **不提交 Git**（`.gitignore` 已排除 `.qoderwork/logs/`）

---

## docs/ — 工程文档

### context/ — Layer 2 按需加载（Git 追踪）

> 通过 `/load-context` 命令按需注入到会话，避免每次全量消耗 context。

| 文件 | 内容 |
|------|------|
| `architecture.md` | 项目背景与定位：业务现状、问题域、系统设计决策，帮助 AI 理解项目需要解决的问题 |
| `constraints.md` | 项目约束与边界（技术限制、业务规则）|
| `adr/NNN-*.md` | 架构决策记录（ADR），每个决策独立文件 |

**ADR 命名规范**：`NNN-短横线描述.md`，如 `001-adopt-qoderharness-paradigm.md`

---

### standards/ — 工程规范（Git 追踪）

> 修改代码前 AI 必须主动读取对应规范文件。

| 文件 | 触发场景 |
|------|---------|
| `comment-style.md` | 任何代码修改 |
| `git-convention.md` | 任何 `git commit` / `git push` |
| `workflow.md` | 制定会话计划或任务规划时 |
| `migration-guide.md` | 执行 `/paradigm-init` 或 `/paradigm-adopt` 时 |

---

### private/ — 私有文档（不提交 Git）

`.gitignore` 已排除 `docs/private/*`（保留 `.gitkeep`）。

| 路径 | 内容 |
|------|------|
| `state/wip.md` | 跨会话进行中工作清单 |
| `state/handoff.md` | 会话交接备忘（每次只保留最新）|
| 其他 `*.md` | 个人操作手册、落地示例、规划笔记等 |

> 会话结束时通过 `/update-state` 更新 `state/` 三件套，通过 `/archive-session` 将精炼内容写入 `~/Documents/PersonalKnowledge/`。

---

*最后更新：2026-05-01 | 配套文档：`AGENTS.md`（行为规范）、`STATE.md`（项目状态）*

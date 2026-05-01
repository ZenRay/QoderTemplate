# .qoder 目录说明

本目录为 Qoder 工程化配置中心，包含项目级配置、自定义命令、技能和子 Agent 定义。

---

## 目录结构

```
.qoder/
├── agents/              # 自定义子 Agent（独立上下文，专职任务）
├── commands/            # 自定义斜杠命令（Prompt 模板，/命令名 触发）
│   ├── archive-session.md   # /archive-session
│   ├── update-state.md      # /update-state
│   ├── load-context.md      # /load-context
│   ├── review-hooks.md      # /review-hooks
│   ├── paradigm-init.md     # /paradigm-init
│   ├── paradigm-adopt.md    # /paradigm-adopt
│   └── paradigm-sync.md     # /paradigm-sync
├── notes/               # 会话草稿笔记（私有，不提交 Git）
│   └── .gitkeep
├── repowiki/            # 代码库 Wiki（Qoder 自动生成，勿手动编辑 meta）
├── skills/              # 自定义技能（多步骤工作流）
│   └── KnowledgeExtractor.md
├── setting.json         # 项目级配置（Git 追踪，团队共享）
├── setting.local.json   # 本地私有覆盖（不提交 Git）
└── README.md            # 本文件
```

---

## setting.json 配置说明

### permissions — 权限策略

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

### hooks — 生命周期钩子

> ⚠️ **IDE 插件限制**：仅支持 5 个事件（UserPromptSubmit / PreToolUse / PostToolUse / PostToolUseFailure / Stop）。
> PreCompact 和 SessionEnd 为 CLI 专属，在 IDE 中配置后不生效。

| 事件 | 脚本 | 行为 |
|------|------|------|
| `UserPromptSubmit` | `prompt-guard.sh` | 拦截 Prompt 注入攻击模式 |
| `PreToolUse (Bash)` | `security-gate.sh` | 阻断高危命令（rm -rf、DROP TABLE 等） |
| `PostToolUse (Write\|Edit)` | `auto-lint.sh` | 自动运行对应语言 Lint |
| `PostToolUseFailure (*)` | `log-failure.sh` | 记录失败日志到 `.qoderwork/logs/failure.log` |
| `Stop` | `notify-done.sh` | 发送 macOS 桌面通知，消息含 stop_reason |
| `PreCompact` *(CLI 专属)* | `knowledge-trigger.sh` | 提示执行知识归档 |
| `SessionEnd` *(CLI 专属)* | `knowledge-trigger.sh` | 会话退出时提示归档 |

---

### userConfig — 用户自定义配置

AI 执行命令和技能时会读取此段，用于控制功能开关。

#### `paradigmTemplateVersion` — 范式模板版本

```json
"paradigmTemplateVersion": "V0.9"  // 记录本项目最后执行 /paradigm-init 或 /paradigm-sync 时使用的模板版本
```

影响命令：`/paradigm-sync`（Phase 2-A 版本比对的基准）

#### `knowledgeArchive` — 归档写入开关

```json
"knowledgeArchive": {
  "enabled": true,          // true=写入文件；false=仅生成预览
  "targetDir": "~/Documents/PersonalKnowledge"  // 归档目标目录，可自定义
}
```

影响命令：`/archive-session`

#### `knowledgeNotes` — 草稿笔记开关

```json
"knowledgeNotes": {
  "enabled": true,          // true=允许 AI 主动创建草稿；false=不创建
  "notesDir": ".qoder/notes"  // 草稿存放目录
}
```

影响行为：AI 在会话中主动整理草稿笔记时，检查此开关决定是否写入 `notesDir`。

---

## commands — 斜杠命令

在对话框输入 `/命令名` 触发，Qoder 自动注入命令内容为 Prompt。

| 命令 | 文件 | 用途 |
|------|------|------|
| `/archive-session` | `commands/archive-session.md` | 提炼本次会话内容，归档至 PersonalKnowledge |
| `/update-state` | `commands/update-state.md` | 更新项目状态三件套（STATE.md / wip.md / handoff.md）|
| `/load-context` | `commands/load-context.md` | 按需加载 `docs/context/` 下的架构文档到当前会话 |
| `/review-hooks` | `commands/review-hooks.md` | 触发 hooks-reviewer Agent 对 Hooks 做深度分析 |
| `/paradigm-init` | `commands/paradigm-init.md` | 绿地新项目初始化（1 轮问答 + 7 步自动）|
| `/paradigm-adopt` | `commands/paradigm-adopt.md` | 棕地老项目渐进式采纳范式（分模块审计 + 确认）|
| `/paradigm-sync` | `commands/paradigm-sync.md` | 已采纳项目跟进模板升级（分级报告 + 选择应用）|

### `/load-context` 参数说明

```
/load-context [target]
```

| target | 加载内容 |
|--------|----------|
| 无参数 | `architecture.md` + `constraints.md`（默认组合）|
| `arch` | 仅 `docs/context/architecture.md` |
| `constraints` | 仅 `docs/context/constraints.md` |
| `adr` | `docs/context/adr/` 下所有 ADR 文件 |
| `adr-NNN` | 指定编号 ADR，如 `adr-001` |
| `all` | 全部 docs/context/ 文档 |

---

## skills — 技能

比斜杠命令更详细的多步骤工作流，通常由命令调用或直接描述触发。

| 技能 | 文件 | 用途 |
|------|------|------|
| KnowledgeExtractor | `skills/KnowledgeExtractor.md` | 7 步归档流程：分析会话 → 生成文件 → 更新索引 |

---

## notes — 会话草稿笔记

- 存放会话中的临时想法、速记、踩坑记录
- **不提交 Git**（`.gitignore` 已排除 `notes/*`，仅保留 `.gitkeep`）
- 草稿质量达标后，通过 `/archive-session` 提炼到 PersonalKnowledge

---

*最后更新：2026-05-01 | 配套文档：`AGENTS.md`（行为规范）、`STATE.md`（项目状态）、`docs/context/`（Layer 2 架构文档）*

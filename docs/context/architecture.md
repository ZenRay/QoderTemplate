# Architecture — QoderHarness Engineering

> Layer 2 文档：完整架构说明。由 AGENTS.md 指针按需加载，或通过 `/load-context` 命令手动加载。
> 最后更新：2026-05-01

---

## 项目定位

**QoderHarness Engineering** 是一个 **Qoder 工程化范式模板项目**，目标是将 Qoder IDE 的能力（Hooks、权限、知识管理、Agent 行为规范）系统化，形成可复制到其他项目的工程基线。

- **不是**业务项目，**是**元项目（管理如何使用 Qoder 的规范本身）
- **受众**：自己及未来使用此范式的团队
- **复制方式**：将 `.qoder/`、`.qoderwork/`、`AGENTS.md`、`docs/standards/` 整体迁移

---

## 系统架构全景

```
┌─────────────────────────────────────────────────────┐
│                  Qoder IDE 插件                      │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐  │
│  │ AGENTS.md│  │setting.json│  │  斜杠命令          │  │
│  │(行为规范) │  │(权限/配置) │  │ /archive-session │  │
│  └──────────┘  └───────────┘  │ /update-state    │  │
│                                └──────────────────┘  │
└──────────────────────┬──────────────────────────────┘
                       │ 触发
        ┌──────────────▼──────────────┐
        │      Hooks 体系（6脚本）      │
        │  PreToolUse → security-gate  │
        │  PostToolUse → auto-lint     │
        │  PostToolUseFailure → log    │
        │  UserPromptSubmit → guard    │
        │  Stop → notify-done          │
        │  PreCompact → trigger(CLI)   │
        └──────────────┬──────────────┘
                       │ 产出
        ┌──────────────▼──────────────┐
        │        知识管理双层架构       │
        │  草稿层: .qoder/notes/       │
        │  精炼层: ~/PersonalKnowledge/│
        └─────────────────────────────┘
```

---

## 模块说明

### 1. 配置层（`.qoder/`）

| 文件/目录 | 职责 |
|-----------|------|
| `setting.json` | 权限声明、Hooks 路径映射、userConfig 自定义开关 |
| `setting.local.json` | 本地私有覆盖（不提交 Git） |
| `commands/` | 自定义斜杠命令（Markdown prompt 模板） |
| `skills/` | 可复用技能（如 KnowledgeExtractor） |
| `agents/` | 专项子 Agent 定义（当前为空） |
| `repowiki/` | 自动生成的代码库 Wiki（35页，zh 语言） |
| `README.md` | 所有配置项的说明文档 |

### 2. Hooks 体系（`.qoderwork/hooks/`）

按 Hooks 价值分为四层（详见 ADR-001）：

| Tier | 脚本 | 价值 |
|------|------|------|
| T1 安全防护 | `security-gate.sh`、`prompt-guard.sh` | 不可逆操作拦截、注入防护 |
| T2 质量保障 | `auto-lint.sh`、`log-failure.sh` | 代码规范自动执行、失败追踪 |
| T3 体验提升 | `notify-done.sh` | 长任务完成桌面通知 |
| T4 知识积累 | `knowledge-trigger.sh` | 会话知识归档（CLI 专属）|

**IDE 支持限制**：IDE 插件仅支持 5 个事件（UserPromptSubmit / PreToolUse / PostToolUse / PostToolUseFailure / Stop）。PreCompact 和 SessionEnd 为 CLI 专属（详见 ADR-003）。

### 3. 文档体系（`docs/`）

采用三层加载架构：

```
Layer 1: AGENTS.md         ← 自动加载，精简摘要 + 指针（≤150行）
Layer 2: docs/context/     ← 按需加载，完整架构文档（本目录）
Layer 3: PersonalKnowledge ← 不自动加载，跨项目知识库
```

私有文档统一在 `docs/private/`（.gitignore 排除）：
- `state/wip.md` — 跨会话进行中工作
- `state/handoff.md` — 单次会话交接备忘
- `CommonThink.md` — 深度思考记录
- `规划ToDo.md` — 项目任务规划

### 4. 状态管理三件套

| 文件 | 位置 | 追踪 | 职责 |
|------|------|------|------|
| `STATE.md` | 根目录 | Git ✅ | 公开状态看板，≤30行 |
| `wip.md` | `docs/private/state/` | 私有 | 跨会话持续任务 |
| `handoff.md` | `docs/private/state/` | 私有 | 单次会话交接备忘 |

### 5. 知识管理双层架构

```
会话进行中
    ↓ 即时捕获（knowledgeNotes.enabled）
.qoder/notes/           ← 草稿层，不提交 Git
    ↓ /archive-session 触发
~/Documents/PersonalKnowledge/   ← 精炼层，独立管理
    projects/QoderHarness/
    topics/
    areas/
```

---

## 关键数据流

```
用户输入 Prompt
    ↓ UserPromptSubmit
    → prompt-guard.sh  检测注入攻击
    ↓ 通过
AI 执行工具调用
    ↓ PreToolUse(Bash)
    → security-gate.sh 检测高危命令（exit 2 = 阻断）
    ↓ 通过
写入/编辑文件
    ↓ PostToolUse(Write|Edit)
    → auto-lint.sh     按文件类型运行 Lint
    ↓ 工具失败
    → log-failure.sh   记录到 failure.log
会话结束
    ↓ Stop
    → notify-done.sh   macOS 桌面通知
```

---

## 版本历史

| 版本 | Commit | 主要交付 |
|------|--------|----------|
| V0.1 | — | 基础结构：4事件 Hooks、权限配置、AGENTS.md |
| V0.2 | — | Hooks 增强：7事件/6脚本 + 双层知识管理 |
| V0.3 | `f6ddf84` | STATE.md 三件套、斜杠命令、注释规范、AGENTS.md 指针 |

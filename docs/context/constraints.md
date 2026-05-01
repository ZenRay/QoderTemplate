# Constraints — QoderHarness Engineering

> Layer 2 文档：技术约束与边界清单。明确"不做什么"，防止范围蔓延。
> 最后更新：2026-05-01

---

## 项目边界约束

### 这个项目是什么 / 不是什么

| 是 | 不是 |
|----|------|
| Qoder 工程化配置范式模板 | 业务应用项目 |
| 可复制到其他项目的工程基线 | 针对特定技术栈的脚手架 |
| 个人 + 小团队使用的范式 | 企业级合规/审计系统 |
| 文档驱动的工程规范 | 代码框架或 SDK |

---

## 技术约束

### Hooks 约束

| 约束 | 说明 |
|------|------|
| IDE 插件仅支持 5 个事件 | PreCompact / SessionEnd 为 CLI 专属，IDE 中不触发 |
| `exit 2` = 阻断，`exit 0` = 放行 | 仅 `PreToolUse` 和 `UserPromptSubmit` 支持阻断语义 |
| Hooks 脚本必须通过 shellcheck | 零警告是合入标准 |
| 禁止 Hook 脚本产生副作用输出到 stdout | 影响 AI 响应解析，日志写文件而非 echo |

### 权限约束

| 约束 | 说明 |
|------|------|
| 工作区外写入需要显式权限声明 | `setting.json → permissions → allow` 必须列出路径 |
| 不自动申请 `all` 权限 | 仅在沙箱限制导致失败时才申请 |
| `~/Documents/PersonalKnowledge/` 写入前检查开关 | `userConfig.knowledgeArchive.enabled` |

### Git 约束

| 约束 | 说明 |
|------|------|
| 禁止 force-push 到 master | 无论何种情况 |
| commit 前必须经用户确认 | AI 不自动提交 |
| `docs/private/**` 永远不提交 | 已在 .gitignore 按目录排除 |
| commit message 必须使用 Conventional Commits 格式 | `feat:` / `fix:` / `docs:` / `chore:` 等 |

### 代码规范约束

| 约束 | 说明 |
|------|------|
| 代码注释和文档字符串默认使用英文 | 中文仅用于无法用英文准确表达的例外场景 |
| Shell 脚本必须声明事件类型和退出码 | 见 `docs/standards/comment-style.md` |
| 禁止注释掉废弃代码 | 直接删除，Git 有记录 |
| 公共函数必须有文档注释 | 参数、返回值都要说明 |

---

## 功能边界（不做什么）

| 不做 | 原因 |
|------|------|
| 不做 Tier 4 审计 Hooks（操作日志全量记录） | 当前为个人项目，无合规需求；等进入团队使用时再加 |
| 不做 PersonalKnowledge → 方案D（独立 Git 仓库） | 等归档量 > 50 篇后升级，现在过度设计 |
| 不做 knowledge-trigger.sh 在 IDE 中的兼容方案 | IDE 不支持 PreCompact，Hack 绕过不可靠，用 /archive-session 替代 |
| 不做 failure.log 日志轮转 | 等文件 > 1MB 时再加，现在是过度工程 |
| 不做 Obsidian 集成 | 等知识库 > 100 篇时再迁移 |
| 不做多分支工作流 | 个人项目直接在 master 工作，无需分支策略 |

---

## 稳定性约束

以下文件/目录的结构变更需要同步更新多处，改动时需特别谨慎：

| 文件/目录 | 依赖方 |
|-----------|--------|
| `AGENTS.md` | 所有会话的行为基准；SubAgent 启动时必读 |
| `.qoder/setting.json` | Hooks 路径映射；权限白名单；userConfig 开关 |
| `docs/private/` 路径 | `.gitignore` 规则；AGENTS.md 中的引用 |
| `STATE.md` 格式 | `/update-state` 命令依赖其结构 |
| Hook 脚本退出码逻辑 | 阻断/放行语义，改错会影响所有工具调用 |

---

## 文档约束

| 约束 | 说明 |
|------|------|
| `STATE.md` 保持 ≤30 行 | 超出则精简旧内容 |
| `AGENTS.md` 保持 ≤150 行 | 超出则将详情移入 `docs/context/` |
| `handoff.md` 只保留最新一次交接 | 历史不积累 |
| `docs/context/` 文档不超过 200 行/文件 | 过长则拆分 |

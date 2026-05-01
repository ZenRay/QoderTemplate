# AI 辅助开发工作流规范

> 描述使用 Qoder 进行日常开发的标准工作流程。
> 适用于所有基于本范式的项目。

---

## 会话生命周期

每次 Qoder 工作会话分三个阶段：**启动 → 工作 → 收尾**。

### 启动阶段

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | AI 读取 `STATE.md` | 获取当前阶段和最近 commit，自动执行 |
| 2 | 按需读取 `handoff.md` | 恢复上次会话交接内容，当有跨会话任务时 |
| 3 | 按需执行 `/load-context` | 涉及架构设计时加载 Layer 2 文档 |

**触发规则**：以下场景必须在开始工作前加载上下文：
- 跨天或跨会话继续任务 → 读取 `handoff.md`
- 修改系统架构或引入新模块 → `/load-context arch`
- 评估约束或边界 → `/load-context constraints`
- 查阅历史决策 → `/load-context adr`

---

### 工作阶段

#### 任务执行原则

1. **先读规范，再写代码**：任何代码修改前读取 `docs/standards/comment-style.md`
2. **提交前读 Git 规范**：执行 `git commit` 前读取 `docs/standards/git-convention.md`
3. **小步提交**：单一职责，提交信息符合 Conventional Commits 格式
4. **变更预览**：修改配置文件（`.qoder/**`、`.qoderwork/**`）前展示 diff，等待确认

#### 提交信息格式（快速参考）

```
<type>(<scope>): <subject>

type: feat | fix | docs | refactor | chore | test | style
```

示例：
```
feat(hooks): add prompt-guard.sh for injection detection
docs(standards): add workflow.md to paradigm
chore: compact STATE.md to ≤30 lines
```

#### 禁止事项

- 禁止在代码注释中保留废弃代码（删除，Git 有历史记录）
- 禁止 force-push 到 `main` / `master`
- 禁止未经确认直接修改 `setting.json` 或 Hook 脚本

---

### 收尾阶段

会话结束前，按以下顺序执行：

| 步骤 | 命令/操作 | 频率 |
|------|-----------|------|
| 1 | `/update-state` — 同步状态三件套 | **每次**会话结束 |
| 2 | `/archive-session` — 归档会话知识 | 有重要决策或里程碑时 |
| 3 | `git push` — 推送当前 commit | 完成可交付内容后 |

**判断是否需要归档**：
- 做出了影响架构或规范的决策 → 归档
- 完成了一个功能里程碑 → 归档
- 仅例行维护（如更新 ToDo、精简文档）→ 可跳过

---

## 状态文档维护规范

| 文件 | 职责 | 约束 |
|------|------|------|
| `STATE.md` | 项目状态看板（Git 追踪） | **≤30 行**，任何时候超出需立即精简 |
| `docs/private/state/wip.md` | 跨会话持续工作清单 | 私有，不提交 Git |
| `docs/private/state/handoff.md` | 最近一次会话交接备忘 | 私有，每次只保留最新一次 |

---

## Hooks 维护规范

- **日常无需手动维护**：Hooks 在 IDE 运行时自动生效
- **复制范式到新项目后**：立即运行 `/review-hooks` 验证适用性
- **出现误触发**：先查看 `.qoderwork/logs/failure.log`，再运行 `hooks-reviewer` Agent
- **修改 Hook 脚本后**：必须运行 `shellcheck` 验证零警告

---

## 知识管理规范

```
会话中产生的知识
       │
       ├─ 草稿层 → .qoder/notes/（即时捕获，不提交 Git）
       │          由 AI 在会话中主动创建
       │
       └─ 精炼层 → ~/Documents/PersonalKnowledge/（结构化归档）
                  由 /archive-session 命令触发写入
```

- **草稿**：AI 在会话中发现值得记录的洞察时主动创建，格式自由
- **归档**：执行 `/archive-session` 后，按 KnowledgeExtractor 模板生成结构化文档

---

*文件路径：`docs/standards/workflow.md` | 适用于所有基于 QoderHarness 范式的项目*

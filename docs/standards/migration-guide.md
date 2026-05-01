# 范式迁移操作指南

> 本文档描述将 QoderHarness 工程范式复制到其他项目的操作流程。  
> 设计依据：`docs/private/CommonThink.md` §5（范式迁移与命令化复用体系设计）

---

## 迁移场景速查

| 场景 | 描述 | 跳转 |
|------|------|------|
| **绿地（Green Field）** | 全新空项目，从零引入范式 | [→ 场景 A](#场景-a绿地初始化) |
| **棕地（Brown Field）** | 已有项目，渐进式采纳范式 | [→ 场景 B](#场景-b棕地采纳) |
| **范式同步（Sync）** | 已采纳范式的项目，跟进上游更新 | [→ 场景 C](#场景-c范式同步) |

---

## 迁移内容分类框架

迁移时，所有文件按处理方式分为四类：

| 类型 | 具体内容 | 操作 |
|------|----------|------|
| **零修改复用** | `.qoder/commands/`、`.qoder/agents/`、`.qoder/skills/`、`docs/standards/`（本文件除外）、`.qoder/README.md`、`hooks/`（除 `auto-lint.sh`）| 直接 copy，不改任何内容 |
| **少量替换** | `AGENTS.md`（项目名/Repo URL/版本）、`setting.json`（`src/tests` 路径）、`auto-lint.sh`（linter 工具）| 替换 3~5 处占位符（见各场景说明）|
| **全部重建** | `docs/context/`（architecture/constraints/adr）、`docs/private/`（状态三件套）、`STATE.md` | 为新项目重新创建，不照抄 |
| **直接删除** | 范式研发期文档（均已移至 `docs/private/`，不再出现在 Template 中）| 无需操作（`docs/知识材料管理方案.md`、`docs/Hooks配置操作手册.md` 均已内置排除）|

---

## 场景 A：绿地初始化

**适用**：全新空项目（通过 GitHub Template 创建）

### 前提条件

GitHub Repo 已设为 Template Repository（Settings → ☑ Template repository）。  
新项目通过 "Use this template" 按钮创建，骨架文件已复制到位。

> **本地迁移（不经 GitHub Template）**：两种方式均可：
>
> 方式 A（推荐）：直接在新项目目录运行 `/paradigm-init`，命令会自动通过 tarball in-memory 完成骨架复制（本地有副本则使用本地，否则从 GitHub 拉取）。
>
> 方式 B（手动）：本地 git archive 模拟骨架复制：
> ```bash
> mkdir -p <目标目录> && git init <目标目录>
> cd <QoderTemplate路径> && git archive HEAD | tar -x -C <目标目录>
> ```
> 之后按以下步骤正常执行定制化。

### 操作步骤

**Step 1：替换项目标识符**

在新项目根目录下，替换以下内容（共 3~5 处）：

| 文件 | 搜索 | 替换为 |
|------|------|--------|
| `AGENTS.md` | `QoderHarness` | 新项目名称 |
| `AGENTS.md` | `ZenRay/QoderTemplate.git` | 新项目 Repo URL |
| `AGENTS.md` | `V0.x` | `V0.1`（重置版本）|
| `STATE.md` | 全部内容 | 见 Step 3 |

**Step 2：调整 `setting.json` 中的路径权限**

```json
"allow": [
  "src/**",     // ← 根据新项目实际源码目录调整
  "tests/**"    // ← 根据新项目实际测试目录调整
]
```

> **非代码项目**（文档型 / 方案探索型 / 研究型）：`src/**` / `tests/**` 无意义，替换为实际目录，例如：
> ```json
> "Edit(./topics/**)",       // 按主题分目录的探索型项目
> "Edit(./docs/context/**)", // 架构与决策文档
> "Edit(./research/**)",     // 研究/实验型项目
> ```
> 如目录结构尚未确定，可先填 `Edit(./**)` 作为宽松占位符，后续收窄。

**Step 3：重置 `STATE.md`**

```markdown
# 项目状态看板

> 最后更新：YYYY-MM-DD | 当前版本：V0.1

## 当前状态
- **阶段**：初始化
- **活跃分支**：main
- **最近 Commit**：`初始提交 hash`

## 进行中
| 事项 | 状态 |
|------|------|
| 范式初始化配置 | 🔄 进行中 |

## 最近决策摘要
- YYYY-MM-DD：采用 QoderHarness 工程范式，基于 Template 初始化
```

**Step 4：调整 `auto-lint.sh` 中的 linter**

根据项目技术栈修改自动检查工具：

| 技术栈 | 推荐 linter | 替换 `ruff` 为 |
|--------|-------------|----------------|
| Python | ruff | `ruff check` |
| JavaScript/TypeScript | ESLint | `eslint` |
| Go | gofmt | `gofmt -l` |
| Rust | clippy | `cargo clippy` |
| Shell | shellcheck | `shellcheck` |
| **文档/Markdown**（非代码项目） | markdownlint-cli | `markdownlint` |

> **非代码项目**：在 `auto-lint.sh` 的 `case` 块中增加 `*.md` 分支：
> ```bash
> *.md)
>   if command -v markdownlint &>/dev/null; then
>     markdownlint "$file" 2>&1 || exit_code=$?
>   fi
>   ;;
> ```

**Step 5：重建 `docs/context/`**

> **⚠️ 注意（GitHub Template 继承问题）**：通过模板创建的项目会复制 QoderHarness 的旧 ADR 文件（`001-hooks-tier-system.md` 等），这些内容**特定于 QoderHarness**，不适用于新项目。重建前须**删除这些文件**（而非清空内容或用占位符替换）：
> ```bash
> # 删除继承的 QoderHarness 专属 ADR——这些文件不应在新项目中存在
> rm docs/context/adr/001-hooks-tier-system.md
> rm docs/context/adr/002-private-docs-directory.md
> rm docs/context/adr/003-precompact-hook-workaround.md
> rm docs/context/adr/004-knowledge-management-dual-layer.md
> # 如项目 security-gate 拦截 rm，改用 Python: python3 -c "import os; [os.remove(f'docs/context/adr/{f}') for f in ['001-hooks-tier-system.md','002-private-docs-directory.md','003-precompact-hook-workaround.md','004-knowledge-management-dual-layer.md'] if os.path.exists(f'docs/context/adr/{f}')]"
> # 同理，清空（不是删除）architecture.md 和 constraints.md 中的旧内容
> ```

```bash
mkdir -p docs/context/adr
# 按新项目实际情况创建：
# docs/context/architecture.md   ← 新项目架构设计
# docs/context/constraints.md    ← 新项目技术约束
# docs/context/adr/ADR-001-xxx.md
```

**Step 6：重建 `docs/private/`（不提交 Git）**

```bash
mkdir -p docs/private/state
# 创建三件套：
# docs/private/state/STATE.md（已在 Step 3 处理）
# docs/private/state/wip.md
# docs/private/state/handoff.md
```

**Step 7：验收清单**

- [ ] `AGENTS.md` 中项目名、Repo URL、版本已替换
- [ ] `STATE.md` 内容已重置为新项目初始状态
- [ ] `setting.json` 路径权限与新项目目录匹配
- [ ] `auto-lint.sh` linter 工具与技术栈匹配
- [ ] `docs/context/` 已重建（哪怕是空目录占位）
- [ ] `docs/private/` 已创建且已加入 `.gitignore`
- [ ] 范式研发期历史文档已删除

---

## 场景 B：棕地采纳

**适用**：已有代码和目录结构的项目，需要渐进引入范式

### 核心原则

- **不覆盖**：永远不自动覆盖目标项目已有的同名文件
- **分模块**：按影响从小到大逐步导入，不要求一次全量迁移
- **幂等性**：每个步骤可安全重复执行

### 推荐导入顺序（影响从小到大）

```
1. docs/standards/    → 影响最小，纯文档，无冲突风险
2. .qoder/commands/   → 只新增命令，不改现有文件
3. .qoder/agents/     → 只新增 Agent，不改现有文件
4. .qoder/skills/     → 只新增 Skill，不改现有文件
5. .qoderwork/hooks/  → 影响运行时行为，需确认现有 hooks
6. .qoder/setting.json → 影响权限配置，需合并而非覆盖
7. AGENTS.md          → 影响最大，需要深度定制，放最后
```

### Step-by-Step

**Step 1：导入标准文档（安全，直接复制）**

```bash
cp -r QoderHarness/docs/standards/ <目标项目>/docs/standards/
# 已有同名文件时，逐个对比后手动合并
```

**Step 2：导入命令和 Agent**

```bash
cp -r QoderHarness/.qoder/commands/ <目标项目>/.qoder/commands/
cp -r QoderHarness/.qoder/agents/   <目标项目>/.qoder/agents/
cp -r QoderHarness/.qoder/skills/   <目标项目>/.qoder/skills/
```

**Step 3：导入 Hooks（需要逐个确认）**

检查目标项目是否已有 `.qoderwork/hooks/`：
- **无**：直接复制整个目录
- **有**：逐个脚本对比，避免覆盖已有自定义脚本

需要修改 `auto-lint.sh` 中的 linter（同场景 A Step 4）。

**Step 4：合并 `setting.json`**

不要直接覆盖，要手动合并：
- 保留目标项目已有的权限配置
- 新增 QoderHarness 中的开关配置（`knowledgeArchive`、`knowledgeNotes` 等）

**Step 5：定制 `AGENTS.md`**

不要直接覆盖目标项目的 `AGENTS.md`（如果已存在）。  
参考 QoderHarness 的 `AGENTS.md`，手动将以下段落合并进去：
- 上下文加载规则表
- SubAgent 广播规则
- 代码规范引用段落
- 项目结构说明（更新为目标项目的实际结构）

**Step 6：创建三件套和 `STATE.md`**

同场景 A Step 3、Step 6。

**Step 7：验收清单**

- [ ] `docs/standards/` 已导入
- [ ] `.qoder/commands/`、`agents/`、`skills/` 已导入
- [ ] Hooks 已导入，无冲突，linter 已调整
- [ ] `setting.json` 已合并（非覆盖）
- [ ] `AGENTS.md` 已按目标项目实际情况定制
- [ ] 三件套和 `STATE.md` 已创建
- [ ] `.gitignore` 已加入 `docs/private/`

---

## 场景 C：范式同步

**适用**：已采纳范式的项目，需要跟进 QoderHarness 上游的范式更新

### 同步前：评估变更范围

先确认上游更新了什么（查看 QoderHarness git log 或 AGENTS.md 版本号）：

| 变更类型 | 描述 | 风险 |
|----------|------|------|
| **Breaking** | 命令接口变更、setting.json 结构调整 | 高，需手动处理 |
| **Enhancement** | 新增命令/Agent/规范文档 | 低，可直接同步 |
| **Optional** | 文档描述优化、注释补充 | 可跳过 |

### 按模块同步

**低风险模块（Enhancement，可直接同步）**：
- 新增的 `.qoder/commands/`
- 新增的 `.qoder/agents/`
- `docs/standards/` 的新增文件或内容增补

**中风险模块（需对比后合并）**：
- `docs/standards/` 的已有文件内容修改
- Hooks 脚本逻辑变更

**高风险模块（需手动评估，不自动同步）**：
- `AGENTS.md` 结构调整（可能与项目定制化冲突）
- `setting.json` 结构变更（需理解变更意图再决定）

### 验收

- [ ] 确认同步后 `AGENTS.md` 行数仍 ≤150 行
- [ ] 确认 `STATE.md` 行数仍 ≤30 行
- [ ] 运行 `shellcheck .qoderwork/hooks/*.sh` 零警告
- [ ] 运行 `/review-hooks` 确认 Hooks 适用性

---

## 附录：常见占位符替换清单

迁移时需要在目标项目中搜索并替换以下内容：

| 占位符（来自 QoderHarness）| 替换为 | 出现位置 |
|---------------------------|--------|---------|
| `QoderHarness` | 新项目名 | `AGENTS.md`、`STATE.md` |
| `ZenRay/QoderTemplate.git` | 新项目 Repo URL | `AGENTS.md` |
| `V0.x`（版本号）| `V0.1` | `AGENTS.md`、`STATE.md` |
| `ruff` | 对应 linter | `auto-lint.sh` |
| `src/**`, `tests/**` | 实际目录路径 | `setting.json` |

---

*文件路径：`docs/standards/migration-guide.md` | 随范式演进持续更新*  
*设计依据：`docs/private/CommonThink.md` §5*

---
description: 棕地老项目渐进式采纳 QoderHarness 工程范式，分模块导入，冲突检测，幂等可重跑
---

# /paradigm-adopt — 棕地项目范式采纳

将 QoderHarness 工程范式渐进式引入**已有项目**。
分模块审计 → 逐模块展示 diff → 用户确认 → 执行。全程不自动覆盖已有内容。

> **与 /paradigm-init 的区别**：
> - `/paradigm-init`：空项目，直接初始化，1 轮问答，全自动
> - `/paradigm-adopt`：已有项目，逐模块审计 + 用户确认，幂等可重跑

---

## 执行流程

### Phase 1：信息收集（1 次交互）

向用户提出以下问题（**合并为一次询问**）：

1. **QoderTemplate 路径**：
   - 自动查找 `~/Documents/QoderTemplate` 和 `../QoderTemplate`
   - 找到则直接使用，找不到才询问
2. **目标项目类型**：`code` / `docs` / `mixed`（用于后续 auto-lint.sh 定制）
3. **采纳范围**（多选）：
   - `[全量]` 按标准顺序逐模块引导
   - `[仅规范文档]` 只引入 `docs/standards/`
   - `[仅命令体系]` 只引入 `.qoder/commands/` + `agents/` + `skills/`
   - `[仅 Hooks]` 只引入 `.qoderwork/hooks/` + `setting.json` 部分
   - `[仅状态管理]` 只引入 `STATE.md` + `docs/private/state/` 三件套

> 收到回答后进入 Phase 2，不再追问。

**采纳范围 → 模块过滤映射**：

| 选择 | 执行的模块 |
|------|----------|
| 全量 | 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 |
| 仅规范文档 | 1 |
| 仅命令体系 | 2 → 3 → 4 |
| 仅 Hooks | 5 → 6 |
| 仅状态管理 | 8（含 .gitignore 检查） |

---

### Phase 2：全局审计（自动执行，无交互）

扫描目标项目，生成冲突报告，作为后续执行的依据。

#### 2-A 检测 QoderTemplate 路径

```python
import os
candidates = [
    os.path.expanduser('~/Documents/QoderTemplate'),
    os.path.join(os.path.dirname(os.getcwd()), 'QoderTemplate'),
]
template_path = next((p for p in candidates if os.path.exists(f'{p}/.qoder/setting.json')), None)
```

#### 2-B 逐模块冲突检测

对每个模块，判断状态：

| 状态码 | 含义 | 后续操作 |
|--------|------|----------|
| `NEW` | 目标项目不存在此文件/目录 | 直接复制，无需确认 |
| `IDENTICAL` | 文件存在且与模板完全一致 | 跳过（已采纳） |
| `CONFLICT` | 文件存在但内容不同（已定制） | 展示 diff，用户决策 |
| `PARTIAL` | 目录存在但文件不全（部分采纳） | 只补充缺失文件 |

检测的模块清单（按影响从小到大）：

```
Module 1: docs/standards/
Module 2: .qoder/commands/
Module 3: .qoder/agents/
Module 4: .qoder/skills/
Module 5: .qoderwork/hooks/
Module 6: .qoder/setting.json
Module 7: AGENTS.md
Module 8: STATE.md + docs/private/state/（三件套）
```

#### 2-C 输出审计摘要

执行 Phase 2 后，展示摘要（不执行任何操作）：

```
📋 审计结果 — <目标项目名>

Module 1: docs/standards/        → NEW（4 个文件，全部缺失）
Module 2: .qoder/commands/       → PARTIAL（缺 paradigm-init.md、review-hooks.md）
Module 3: .qoder/agents/         → IDENTICAL（已采纳，跳过）
Module 4: .qoder/skills/         → NEW
Module 5: .qoderwork/hooks/      → CONFLICT（auto-lint.sh 已有自定义内容）
Module 6: .qoder/setting.json    → CONFLICT（存在但缺少 knowledgeArchive 开关）
Module 7: AGENTS.md              → CONFLICT（存在自定义版本，需合并 3 个段落）
Module 8: STATE.md + 三件套      → NEW（均不存在）

建议执行顺序：1 → 2 → 4 → 8 → 5 → 6 → 7（3 已完成，跳过）
```

---

### Phase 3：逐模块采纳（按模块逐一确认）

对每个非 `IDENTICAL` 的模块，逐一执行以下流程：

```
展示变更内容 → 用户确认（执行 / 跳过 / 查看 diff）→ 执行
```

**"展示 diff" 的实现方式**（AI 读取两个文件后逐段对比展示）：
```python
import difflib
with open(src) as f: src_lines = f.readlines()
with open(dst) as f: dst_lines = f.readlines()
diff = difflib.unified_diff(dst_lines, src_lines,
                            fromfile='当前版本', tofile='模板版本', lineterm='')
print('\n'.join(list(diff)[:60]))  # 最多展示 60 行，避免刷屏
```

#### Module 1：docs/standards/（规范文档）

**冲突处理**：
- `NEW`：直接复制 4 个文件（comment-style / git-convention / workflow / migration-guide）
- `CONFLICT`：逐文件展示 diff，每个文件独立确认（合并/跳过/覆盖）
- `PARTIAL`：只复制缺失的文件

执行示例：
```python
import shutil, os

for fname in ['comment-style.md', 'git-convention.md', 'workflow.md', 'migration-guide.md']:
    src = f'{template_path}/docs/standards/{fname}'
    dst = f'{target_path}/docs/standards/{fname}'
    if not os.path.exists(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
    # 已存在的文件：展示 diff，等待用户确认
```

#### Module 2：.qoder/commands/ + .qoder/notes/（斜杠命令 + 草稿层）

**冲突处理**：
- 逐文件检查：`NEW` 的直接复制，`CONFLICT` 的展示 diff
- **特别注意**：`archive-session.md`、`update-state.md` 可能已有定制版本，优先保留用户版本
- `.qoder/notes/`：目录不存在则创建（空目录，草稿层）；已存在则跳过

#### Module 3：.qoder/agents/ 和 Module 4：.qoder/skills/

**冲突处理**：
- `NEW`：直接复制（`hooks-reviewer.md`、`KnowledgeExtractor.md`）
- `IDENTICAL`：跳过
- `CONFLICT`：展示 diff，用户决定

#### Module 5：.qoderwork/hooks/（Hooks 脚本）

**冲突处理**：这是高风险模块，单独处理每个脚本：

| 脚本 | 冲突策略 |
|------|---------|
| `security-gate.sh` | 展示 diff；若已定制则提示合并拦截规则 |
| `prompt-guard.sh` | 同上 |
| `auto-lint.sh` | **特殊处理**：不整体覆盖，只补充缺失的语言分支（用 Phase 1 的项目类型决定添加哪些） |
| `log-failure.sh` | `NEW` 直接复制；`CONFLICT` 展示 diff |
| `notify-done.sh` | 同上 |
| `knowledge-trigger.sh` | 同上 |

`auto-lint.sh` 冲突时的处理逻辑：
```
对比两个版本的 case 分支列表：
  模板有、目标没有的分支 → 提示添加
  目标有、模板没有的分支 → 保留（用户自定义）
  两者都有的分支 → 比较逻辑，展示 diff
```

每个脚本执行后验证：`shellcheck <file>` 零警告。

#### Module 6：.qoder/setting.json（权限与开关配置）

**永远不整体覆盖**，只做精确合并：

1. **合并 `userConfig` 开关**（目标文件缺少时追加）：
   ```json
   "knowledgeArchive": { "enabled": true, "targetDir": "~/Documents/PersonalKnowledge", ... }
   "knowledgeNotes":   { "enabled": true, "notesDir": ".qoder/notes", ... }
   ```

2. **合并 `hooks` 事件配置**（检查每个事件是否已注册）：
   ```
   对比模板和目标的 hooks 配置：
     - 模板有、目标没有的事件 → 提示添加
     - 两者都有同一事件 → 展示差异，用户决定是否合并
   ```

3. **不动 `permissions`**：路径权限是项目专属配置，不从模板复制

执行后展示：合并了哪些 key，跳过了哪些。

#### Module 7：AGENTS.md（行为规范文件）

**最高风险模块，绝不整体覆盖。**

首先判断冲突类型：
- `NEW`：走 `/paradigm-init` 的 Step 1 逻辑（复制 + 定制化替换）
- `CONFLICT`：进入精确段落合并模式

**精确段落合并（CONFLICT 时）**：

检查目标 AGENTS.md 是否包含以下 3 个关键段落，缺少的逐段提示合并：

| 段落 | 检测标志字符串 | 缺失时的操作 |
|------|---------------|-------------|
| 上下文加载规则 | `## 上下文加载规则` | 展示模板段落，提示插入位置 |
| SubAgent 广播规则 | `## SubAgent 广播规则` | 展示模板段落，提示插入位置 |
| Code Standards 规范引用 | `docs/standards/comment-style.md` | 展示模板段落，提示插入位置 |

对每个缺失段落：
```
展示段落内容 →
用户确认：[插入到 AGENTS.md] / [跳过] →
若插入：追加到文件末尾（安全位置）或提示用户手动定位
```

#### Module 8：STATE.md + docs/private/ 三件套

**STATE.md**：
- `NEW`：用 `/paradigm-init` Step 3 的模板创建
- `CONFLICT`：不覆盖；展示模板格式，提示用户参考调整

**docs/private/state/ 三件套**（wip.md + handoff.md）：
- `NEW`：创建（内容参考 `/paradigm-init` Step 6）
- 已存在：跳过（私有文件，不干预）

**`.gitignore` 检查**（无论 NEW/CONFLICT 均执行）：
```python
with open('.gitignore', 'a+') as f:
    f.seek(0)
    content = f.read()
    missing = [line for line in ['docs/private/', '.qoder/notes/', '.qoder/setting.local.json']
               if line not in content]
    if missing:
        f.write('\n# QoderHarness private dirs\n')
        f.write('\n'.join(missing) + '\n')
        print(f'  → .gitignore 追加: {missing}')
```

---

### Phase 4：采纳后定制化

所有模块执行完毕后，针对本次**新采纳的**模块做定制化（已有的跳过）：

| 条件 | 执行操作 |
|------|---------|
| AGENTS.md 为 NEW（新建） | 执行 `/paradigm-init` Step 1 替换逻辑（项目名/URL/版本/路径） |
| setting.json 新增了权限 | 提示检查 `Edit()` 路径是否与目标项目目录匹配 |
| auto-lint.sh 新建或修改 | 运行 `shellcheck` 验证；根据项目类型提示 linter 配置 |
| docs/context/ 不存在 | 提示：建议创建 `docs/context/` 骨架（非强制，用户决定） |

---

### Phase 5：验收 + 完成报告

#### 验收检查

```python
import subprocess, os

def check_shellcheck():
    hooks_dir = '.qoderwork/hooks'
    if not os.path.exists(hooks_dir):
        return True  # 未采纳 Hooks 模块，跳过
    results = []
    for sh in os.listdir(hooks_dir):
        if sh.endswith('.sh'):
            r = subprocess.run(['shellcheck', f'{hooks_dir}/{sh}'], capture_output=True)
            results.append(r.returncode == 0)
    return all(results)

checks = {
    "docs/standards/ 规范文档": os.path.exists('docs/standards/comment-style.md'),
    ".qoder/commands/ 命令体系": os.path.exists('.qoder/commands/archive-session.md'),
    ".qoder/skills/ KnowledgeExtractor": os.path.exists('.qoder/skills/KnowledgeExtractor.md'),
    "setting.json knowledgeArchive 开关": 'knowledgeArchive' in open('.qoder/setting.json').read(),
    "docs/private/ 在 .gitignore": 'docs/private' in open('.gitignore').read(),
    "STATE.md 存在": os.path.exists('STATE.md'),
    "shellcheck 零警告": check_shellcheck(),
}
```

> STATE.md 验收使用**特有标识检测**（同 /paradigm-init Step 7）：
> 检查 `['V0.7', 'V0.8', 'Template 清洁化', 'repowiki', 'ZenRay/QoderTemplate']` 不存在

#### 完成报告格式

```
✅ /paradigm-adopt 完成

项目：{目标项目名}
类型：{code|docs|mixed}
路径：{绝对路径}

模块采纳结果：
  ✅ docs/standards/      — 4 个文件全部导入
  ✅ .qoder/commands/     — 新增 2 个命令（paradigm-init / review-hooks）
  ⏭  .qoder/agents/       — 已采纳，跳过
  ✅ .qoder/skills/       — KnowledgeExtractor 导入
  ⚠️  .qoderwork/hooks/   — auto-lint.sh 冲突，*.md 分支已合并；其余 5 个直接导入
  ✅ setting.json         — 合并 knowledgeArchive + knowledgeNotes 开关
  ✅ AGENTS.md            — 合并 3 个段落（上下文加载规则 / SubAgent 广播 / Code Standards）
  ✅ STATE.md + 三件套    — 新建

需手动处理：
  ⬜ AGENTS.md — 检查合并段落的位置是否合适
  ⬜ setting.json permissions — 确认 Edit() 路径与项目实际目录匹配
  ⬜ docs/context/ — 建议创建（architecture.md + constraints.md + adr/）
  ⬜ 执行 git commit
     建议：feat: adopt QoderHarness paradigm via /paradigm-adopt

建议下一步：
  → 运行 /review-hooks 检查 Hooks 适用性
  → 运行 /update-state 更新状态看板
```

---

## 幂等性保证

`/paradigm-adopt` 设计为可安全重复运行：

| 重跑场景 | 行为 |
|----------|------|
| 某模块上次跳过，本次要补充 | 正常检测，按当前状态执行 |
| 某模块已采纳（IDENTICAL）| 自动跳过，不重复操作 |
| 上次部分执行后中断 | 从 Phase 2 审计开始，只处理未完成的模块 |
| 模板版本更新后重跑 | 重新检测所有模块，显示新 diff |

---

## 错误处理

| 情况 | 处理方式 |
|------|----------|
| 找不到 QoderTemplate 路径 | 停止，提示用户提供路径 |
| 目标项目不是 Git 仓库 | 警告，询问是否继续（某些功能依赖 git） |
| shellcheck 有警告 | 显示警告，不阻断，报告中标注 ⚠️ |
| AGENTS.md 合并后超过 150 行 | 警告：`AGENTS.md 建议 ≤150 行，当前 XX 行，请考虑精简` |
| setting.json 解析失败（格式错误）| 停止 Module 6，提示用户先修复 JSON 格式 |

---

*参考：`docs/standards/migration-guide.md` 场景 B（棕地采纳）*
*设计依据：`docs/private/CommonThink.md` §5（Hybrid 路径 C）*

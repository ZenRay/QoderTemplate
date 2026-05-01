---
description: 已采纳 QoderHarness 范式的下游项目，跟进模板版本升级，增量 diff + 分级报告 + 选择性应用
---

# /paradigm-sync — 范式版本同步

下游项目（已通过 `/paradigm-init` 或 `/paradigm-adopt` 引入范式）跟进 QoderTemplate 的更新。

> **与其他命令的区别**：
> - `/paradigm-init`：绿地初始化，只跑一次
> - `/paradigm-adopt`：棕地首次引入，强调冲突检测
> - `/paradigm-sync`：**已采纳项目**的增量更新，强调分级报告 + 选择性应用

---

## 前提条件

- 当前项目已通过 `/paradigm-init` 或 `/paradigm-adopt` 引入范式
- `AGENTS.md` 中有 `Current version` 字段（记录初始化时使用的模板版本）
- 本地可访问 QoderTemplate 目录（或 git remote）

---

## 执行流程

### Phase 1：信息收集（自动 + 最多 1 次询问）

```python
import os

# 自动查找 QoderTemplate 路径
candidates = [
    os.path.expanduser('~/Documents/QoderTemplate'),
    os.path.join(os.path.dirname(os.getcwd()), 'QoderTemplate'),
]
template_path = next((p for p in candidates if os.path.exists(f'{p}/.qoder/setting.json')), None)
# 找不到才询问用户
```

询问问题（找不到路径时才出现）：
- QoderTemplate 的本地路径是什么？

> 路径确认后直接进入 Phase 2，不再追问。

---

### Phase 2：版本比对（自动，无交互）

#### 2-A 读取版本信息

```python
import re

# 当前项目版本（从 AGENTS.md 的 Current version 字段读取）
with open('AGENTS.md') as f:
    agents_content = f.read()
# 模式：**Current version**: V0.x  或  Current version: V0.x
m = re.search(r'[Cc]urrent\s+version[:\*\s]+V(\S+)', agents_content)
downstream_version = m.group(1) if m else 'unknown'

# 模板最新版本（从 QoderTemplate/STATE.md 读取）
with open(f'{template_path}/STATE.md') as f:
    state_content = f.read()
m = re.search(r'V(\d+\.\d+)', state_content)
template_version = m.group(1) if m else 'unknown'

print(f'当前项目范式版本: V{downstream_version}')
print(f'模板最新版本:     V{template_version}')
```

若版本相同：报告"范式已是最新版本"，退出。

#### 2-B 逐模块文件 diff

对每个模块的每个文件，判断变更类型：

| 变更类型 | 判断逻辑 | 默认处理 |
|---------|---------|---------|
| `UNCHANGED` | 两端文件完全一致 | 跳过 |
| `UPSTREAM_NEW` | 模板有但下游没有（新增功能） | Enhancement |
| `UPSTREAM_UPDATED` | 两端都有，但内容不同 | 进一步分级 |
| `DOWNSTREAM_ONLY` | 下游有但模板没有（用户新增）| 保留，不处理 |

扫描范围（与 /paradigm-adopt 相同的 8 个模块）：

```
Module 1: docs/standards/
Module 2: .qoder/commands/
Module 3: .qoder/agents/
Module 4: .qoder/skills/
Module 5: .qoderwork/hooks/
Module 6: .qoder/setting.json（只比对 userConfig 和 hooks 两个 key）
Module 7: AGENTS.md（只比对 3 个关键段落）
Module 8: STATE.md（不处理，用户私有状态）
```

> **Module 8 例外**：STATE.md 是项目运行状态，不从模板同步。

#### 2-C 变更分级

对 `UPSTREAM_UPDATED` 的文件，按以下规则自动分级：

| 级别 | 触发条件 | 示例 |
|------|---------|------|
| `BREAKING` | Hooks exit 逻辑变化；security-gate 新增拦截规则；setting.json 新增必填 key | security-gate.sh 新增拦截命令 |
| `ENHANCEMENT` | 新斜杠命令；新 agent/skill；标准文档更新；hooks 新增语言分支 | 新增 paradigm-adopt.md |
| `OPTIONAL` | 注释修改；格式调整；文档措辞优化 | comment-style.md 措辞调整 |

**分级判断伪逻辑**：
```
if 文件是 hooks/*.sh 且 exit_code 逻辑有变化:
    → BREAKING
elif 文件是 .qoder/commands/ 且是新文件:
    → ENHANCEMENT (UPSTREAM_NEW)
elif diff 行数 < 5 且全是注释/空行变化:
    → OPTIONAL
else:
    → ENHANCEMENT（默认保守）
```

---

### Phase 3：分级报告（展示，等待用户决策）

```
📊 /paradigm-sync 报告 — <项目名>
版本：V{downstream_version} → V{template_version}

🔴 BREAKING（需要关注，可能影响现有行为）
  .qoderwork/hooks/security-gate.sh
    + 新增拦截规则: "docker system prune"
    + 新增拦截规则: "pip install --user"

🟡 ENHANCEMENT（新功能，建议引入）
  .qoder/commands/paradigm-adopt.md    [UPSTREAM_NEW] 新文件
  .qoder/commands/paradigm-sync.md     [UPSTREAM_NEW] 新文件
  docs/standards/migration-guide.md    [UPSTREAM_UPDATED] +36 行（Gap 修复）
  .qoderwork/hooks/auto-lint.sh        [UPSTREAM_UPDATED] 新增 *.md 分支

🔵 OPTIONAL（优化，按需引入）
  docs/standards/comment-style.md     [UPSTREAM_UPDATED] 措辞调整 2 处

⏭  SKIPPED（无变化，跳过）
  .qoder/agents/hooks-reviewer.md
  .qoder/skills/KnowledgeExtractor.md
  ... (共 N 个文件)

---
总计：2 Breaking | 4 Enhancement | 1 Optional | N Skipped

请选择要应用的级别（可多选）：
  [1] 应用全部 BREAKING
  [2] 应用全部 ENHANCEMENT
  [3] 应用全部 OPTIONAL
  [4] 逐文件确认（每个文件单独决策）
  [5] 只生成报告，不应用任何变更
```

---

### Phase 4：选择性应用

根据用户选择执行：

#### 选项 1/2/3（批量应用某级别）

```python
import shutil, difflib

def apply_file(src, dst, module_type):
    """
    Apply template update to target file.
    module_type: 'overwrite' | 'merge_hooks' | 'merge_agents_md' | 'merge_setting'
    """
    if module_type == 'overwrite':
        shutil.copy2(src, dst)
    elif module_type == 'merge_hooks':
        # auto-lint.sh：合并缺失的 case 分支（不整体覆盖）
        merge_case_branches(src, dst)
    elif module_type == 'merge_agents_md':
        # AGENTS.md：合并缺失的 3 个关键段落
        merge_agents_sections(src, dst)
    elif module_type == 'merge_setting':
        # setting.json：合并 userConfig 开关
        merge_setting_keys(src, dst)
```

各模块的应用策略（同 /paradigm-adopt Phase 3）：

| 模块 | 应用策略 |
|------|---------|
| docs/standards/ | `overwrite`（覆盖，模板权威） |
| .qoder/commands/ | `overwrite`（新文件直接复制；已有文件展示 diff 后覆盖） |
| .qoder/agents/ + skills/ | `overwrite` |
| hooks/security-gate.sh、prompt-guard.sh | `overwrite`（T1 安全脚本，以模板为准） |
| hooks/auto-lint.sh | `merge_case_branches`（不整体覆盖） |
| hooks/其余 | `overwrite` |
| setting.json | `merge_setting_keys` |
| AGENTS.md | `merge_agents_sections` |

#### 选项 4（逐文件确认）

每个变更文件依次展示 diff（最多 60 行）+ 询问：
```
[应用] / [跳过] / [查看完整 diff]
```

#### 选项 5（只报告）

不执行任何文件操作，报告可用于后续手动处理。

---

### Phase 5：同步后处理

#### 更新版本记录

将 AGENTS.md 中的 `Current version` 字段更新为模板最新版本，并补全 Project Structure 命令列表：

```python
import re

with open('AGENTS.md', 'r') as f:
    content = f.read()

# 1. 替换版本号
new_content = re.sub(
    r'(\*\*Current version\*\*:\s*)V[\d.]+',
    f'\\g<1>V{template_version}',
    content
)

# 2. 补全命令树中缺失的 UPSTREAM_NEW 命令文件
# upstream_new_commands = 本次 Phase 4 中实际新增的命令文件列表
for cmd_file in upstream_new_commands:
    if cmd_file not in new_content:
        cmd_name = cmd_file.replace('.md', '')
        # 在命令树末尾追加，使用安全的文本追加方式
        new_content += f'\n<!-- paradigm-sync: added {cmd_file} to commands -->'
        # 提示手动定位到正确位置
        print(f'  ⚠️  {cmd_file} 未在 AGENTS.md 命令树中找到，需手动插入到 .qoder/commands/ 段落')

with open('AGENTS.md', 'w') as f:
    f.write(new_content)
```

> **注意**：命令树更新依赖精确的文本锚点。若自动插入失败，完成报告的"需手动处理"会列出具体缺失的文件，由用户手动更新。

#### 验收检查（仅检查本次实际应用的模块）

```python
# shellcheck（若 Hooks 有变更）
if hooks_were_updated:
    check_shellcheck()  # 同 /paradigm-adopt Phase 5 定义

# AGENTS.md 行数检查
with open('AGENTS.md') as f:
    lines = f.readlines()
if len(lines) > 150:
    print(f'⚠️  AGENTS.md 当前 {len(lines)} 行，建议 ≤150 行')
```

#### 完成报告

```
✅ /paradigm-sync 完成

版本同步：V{downstream_version} → V{template_version}
应用变更：Breaking ×2 | Enhancement ×4 | Optional ×0（已跳过）

应用结果：
  ✅ security-gate.sh    — 已更新（BREAKING）
  ✅ paradigm-adopt.md   — 新增（ENHANCEMENT）
  ✅ paradigm-sync.md    — 新增（ENHANCEMENT）
  ✅ migration-guide.md  — 已更新（ENHANCEMENT）
  ✅ auto-lint.sh        — *.md 分支已合并（ENHANCEMENT）
  ⏭  comment-style.md    — 已跳过（OPTIONAL，用户选择不应用）

需手动处理：
  ⬜ 检查 security-gate.sh 新增拦截规则是否符合项目需求
  ⬜ 执行 git commit
     建议：chore: sync QoderHarness paradigm to V{template_version}
```

---

## 幂等性保证

| 场景 | 行为 |
|------|------|
| 重复运行 | Phase 2 重新扫描，UNCHANGED 文件自动跳过 |
| 部分应用后重跑 | 已应用的文件显示为 UNCHANGED，只剩未应用的变更 |
| 模板又有新更新 | 正常检测出新 diff |

---

## 错误处理

| 情况 | 处理方式 |
|------|----------|
| AGENTS.md 无 `Current version` 字段 | 警告：无法确定基准版本，以文件内容 diff 为准 |
| 下游版本 > 模板版本 | 报告"下游版本领先于模板"，建议检查是否用了本地未提交的模板 |
| setting.json JSON 格式错误 | 跳过 Module 6，报告中标注 ⚠️ |
| shellcheck 有警告 | 不阻断，报告中标注 ⚠️ |

---

*参考：`docs/standards/migration-guide.md` 场景 C（范式同步）*
*设计依据：`docs/private/CommonThink.md` §5（斜杠命令路径 A）*

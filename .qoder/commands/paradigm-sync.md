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
- `.qoder/setting.json` 中有 `paradigmTemplateVersion` 字段（记录上次同步基准）
- 网络可用（本地异常时从 GitHub 自动拉取）或本地有 QoderTemplate 副本

---

## 执行流程

### Phase 1：模板加载（自动，无交互）

```python
import urllib.request, tarfile, io, os

REMOTE_URL = "https://github.com/ZenRay/QoderTemplate/archive/refs/heads/master.tar.gz"
NEEDED_PATHS = [
    ".qoder/commands", ".qoder/agents", ".qoder/skills",
    ".qoderwork/hooks", "docs/standards", "AGENTS.md", "STATE.md"
]

def load_template_in_memory(url=REMOTE_URL, needed_paths=NEEDED_PATHS):
    """Load template files into memory dict. No temp directories required."""
    files = {}
    with urllib.request.urlopen(url) as resp:
        with tarfile.open(fileobj=io.BytesIO(resp.read()), mode="r:gz") as tar:
            for member in tar.getmembers():
                if not member.isfile():
                    continue
                rel = "/".join(member.name.split("/")[1:])  # strip "QoderTemplate-master/"
                if any(rel.startswith(p) for p in needed_paths) and rel:
                    f = tar.extractfile(member)
                    if f:
                        files[rel] = f.read().decode("utf-8")
    return files  # { ".qoder/commands/paradigm-init.md": "content...", ... }

# 路径探测：本地优先，远程兜底
local_candidates = [
    os.path.expanduser("~/Documents/QoderTemplate"),
    os.path.join(os.path.dirname(os.getcwd()), "QoderTemplate"),
]
local_tpl = next(
    (p for p in local_candidates if os.path.exists(f"{p}/.qoder/setting.json")), None
)

if local_tpl:
    # 本地副本：逐文件读入内存字典（不整体复制到目标目录）
    template_files = {}
    for needed in NEEDED_PATHS:
        full = os.path.join(local_tpl, needed)
        if os.path.isfile(full):
            template_files[needed] = open(full, encoding="utf-8").read()
        elif os.path.isdir(full):
            for root, _, fnames in os.walk(full):
                for fname in fnames:
                    abs_f = os.path.join(root, fname)
                    rel_f = os.path.relpath(abs_f, local_tpl)
                    template_files[rel_f] = open(abs_f, encoding="utf-8").read()
    print(f"  ✅ 使用本地模板: {local_tpl}")
else:
    # 远程兜底：tarball in-memory，无需 /tmp 临时目录
    print("  本地未找到 QoderTemplate，从 GitHub 拉取…")
    template_files = load_template_in_memory()
    print("  ✅ 远程模板加载完成（in-memory，无临时文件）")
```

> 无论本地还是远程，`template_files` 均为 `{ rel_path: content }` 内存字典，后续所有阶段使用统一接口。

---

### Phase 2：版本比对（自动，无交互）

#### 2-A 读取版本信息

```python
import json, re

# 上次同步的模板版本（从 setting.json 的 paradigmTemplateVersion 字段读取）
try:
    with open('.qoder/setting.json') as f:
        setting = json.load(f)
    last_synced_version = setting.get('userConfig', {}).get('paradigmTemplateVersion', None)
except Exception:
    last_synced_version = None

if last_synced_version is None:
    print('⚠️  setting.json 未包含 paradigmTemplateVersion 字段，将以文件内容 diff 为准')
    last_synced_version = 'unknown'

# 模板最新版本（从内存字典读取，无需额外 IO）
state_content = template_files.get("STATE.md", "")
m = re.search(r'V(\d+\.\d+)', state_content)
template_version = m.group(1) if m else 'unknown'

print(f'上次同步模板版本: {last_synced_version}')
print(f'模板最新版本:     V{template_version}')
```

若两者版本相同：报告“范式已是最新版本”，退出。

#### 2-B 逐模块文件 diff（全程 in-memory）

直接对内存字典 vs 本地文件进行比对，无需临时目录：

```python
result = {}  # { rel_path: (status, template_content, local_content) }

for rel_path, template_content in template_files.items():
    local_abs = os.path.join(os.getcwd(), rel_path)
    if not os.path.exists(local_abs):
        result[rel_path] = ("UPSTREAM_NEW", template_content, "")
    else:
        with open(local_abs, encoding="utf-8") as f:
            local_content = f.read()
        if local_content == template_content:
            result[rel_path] = ("UNCHANGED", template_content, local_content)
        else:
            result[rel_path] = ("UPSTREAM_UPDATED", template_content, local_content)

# DOWNSTREAM_ONLY：本地有但模板没有
for needed in NEEDED_PATHS:
    for root, _, fnames in os.walk(needed) if os.path.isdir(needed) else []:
        for fname in fnames:
            rel = os.path.relpath(os.path.join(root, fname))
            if rel not in template_files and rel not in result:
                result[rel] = ("DOWNSTREAM_ONLY", "", open(rel, encoding="utf-8").read())
```

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
import difflib

def apply_file(rel_path, template_content, local_content, module_type):
    """
    Apply template update to local file using in-memory content.
    module_type: 'overwrite' | 'merge_hooks' | 'merge_agents_md' | 'merge_setting'
    """
    dst = os.path.join(os.getcwd(), rel_path)
    os.makedirs(os.path.dirname(dst), exist_ok=True)

    if module_type == 'overwrite':
        with open(dst, 'w', encoding='utf-8') as f:
            f.write(template_content)
    elif module_type == 'merge_hooks':
        # auto-lint.sh：合并缺失的 case 分支（不整体覆盖）
        merge_case_branches(template_content, dst)
    elif module_type == 'merge_agents_md':
        # AGENTS.md：合并缺失的 3 个关键段落
        merge_agents_sections(template_content, dst)
    elif module_type == 'merge_setting':
        # setting.json：合并 userConfig 开关
        merge_setting_keys(template_content, dst)
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

将 AGENTS.md 中的 `Current version` 字段更新为模板最新版本，并更新 `setting.json` 的 `paradigmTemplateVersion`：

```python
import json, re

# 1. 更新 AGENTS.md Current version
with open('AGENTS.md', 'r') as f:
    content = f.read()
new_content = re.sub(
    r'(\*\*Current version\*\*:\s*)V[\d.]+',
    f'\\g<1>V{template_version}',
    content
)
with open('AGENTS.md', 'w') as f:
    f.write(new_content)

# 2. 更新 setting.json 的 paradigmTemplateVersion
try:
    with open('.qoder/setting.json') as f:
        setting = json.load(f)
    setting['userConfig']['paradigmTemplateVersion'] = f'V{template_version}'
    with open('.qoder/setting.json', 'w') as f:
        json.dump(setting, f, ensure_ascii=False, indent=2)
except Exception as e:
    print(f'⚠️  setting.json 更新失败: {e}，请手动将 paradigmTemplateVersion 设为 V{template_version}')
```

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

版本同步：{last_synced_version} → V{template_version}
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
  ⬜ AGENTS.md Project Structure 命令树——将本次 UPSTREAM_NEW 的命令文件手动补入：
     在 AGENTS.md 的 `.qoder/commands/` 树形条目下，按照如下格式追加（示例）：
       │   │   ├── paradigm-adopt.md    # /paradigm-adopt
       │   │   └── paradigm-sync.md     # /paradigm-sync
     （实际需补入：{upstream_new_commands_list}，最后一项用 └──，其余用 ├──）
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
| AGENTS.md 无 `Current version` 字段 | 警告并跳过更新；`paradigmTemplateVersion` 正常更新 |
| setting.json 无 `paradigmTemplateVersion` 字段 | 警告：无法确定基准版本，以文件内容 diff 为准 |
| 下游版本 > 模板版本 | 报告“下游版本领先于模板”，建议检查是否用了本地未提交的模板 |
| setting.json JSON 格式错误 | 跳过 Module 6，报告中标注 ⚠️ |
| shellcheck 有警告 | 不阻断，报告中标注 ⚠️ |

---

*参考：`docs/standards/migration-guide.md` 场景 C（范式同步）*
*设计依据：`docs/private/CommonThink.md` §5（斜杠命令路径 A）*

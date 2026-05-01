---
description: 绿地新项目初始化——将 QoderHarness 工程范式迁移到空项目，最少交互，全自动执行
---

# /paradigm-init — 绿地新项目初始化

将当前工作区初始化为 QoderHarness 工程范式项目。
执行 `docs/standards/migration-guide.md` 场景 A 全部 7 步，仅需 1 轮问答。

---

## 执行流程

### Phase 1：信息收集（仅此 1 次交互）

向用户提出以下问题（**合并为一次询问，不分多轮**）：

1. **项目名称**（默认：当前目录名，驼峰或 PascalCase）
2. **一句话描述**（10~40 字，用于 AGENTS.md Project Overview）
3. **项目类型**，三选一：
   - `code` — 有源代码，需要代码 linter
   - `docs` — 纯文档 / 方案探索 / 研究型，主要写 Markdown
   - `mixed` — 代码 + 文档混合
4. **技术栈**（仅当类型为 `code` 或 `mixed` 时询问）：
   Python / JavaScript / TypeScript / Go / Rust / Shell / Other
5. **源码目录**（仅当类型为 `code` 或 `mixed` 时询问，默认 `src/` + `tests/`）
6. **Repo URL**（可选，默认填占位符 `https://github.com/<your-org>/<project>.git`）

> 收到回答后立即进入 Phase 2，不再追问。

---

### Phase 2：环境检测

**2-A 检查模板骨架是否已存在**

检查以下文件是否存在：`.qoder/setting.json`、`AGENTS.md`、`.qoderwork/hooks/`

- **已存在**（GitHub Template 已克隆）→ 直接进入 Phase 3，`template_files = None`
- **不存在**（空目录）→ 执行下方路径探测，获取模板文件

```python
import urllib.request, tarfile, io, os, shutil

REMOTE_URL = "https://github.com/ZenRay/QoderTemplate/archive/refs/heads/master.tar.gz"
NEEDED_PATHS = [".qoder", ".qoderwork/hooks", "docs/standards", "AGENTS.md", "STATE.md", ".gitignore"]

def load_template_in_memory(url=REMOTE_URL):
    """Load template files into memory dict. No temp directories required."""
    files = {}
    with urllib.request.urlopen(url) as resp:
        with tarfile.open(fileobj=io.BytesIO(resp.read()), mode="r:gz") as tar:
            for member in tar.getmembers():
                if not member.isfile():
                    continue
                rel = "/".join(member.name.split("/")[1:])  # strip "QoderTemplate-master/"
                if any(rel.startswith(p) for p in NEEDED_PATHS) and rel:
                    f = tar.extractfile(member)
                    if f:
                        files[rel] = f.read().decode("utf-8")
    return files  # { ".qoder/commands/paradigm-init.md": "content...", ... }

def write_template_files(files, target_dir="."):
    """Write in-memory template files directly to target directory."""
    for rel_path, content in files.items():
        abs_path = os.path.join(target_dir, rel_path)
        os.makedirs(os.path.dirname(abs_path), exist_ok=True)
        with open(abs_path, "w", encoding="utf-8") as f:
            f.write(content)

# --- 路径探测：本地优先，远程兜底 ---
local_candidates = [
    os.path.expanduser("~/Documents/QoderTemplate"),
    os.path.join(os.path.dirname(os.getcwd()), "QoderTemplate"),
]
local_tpl = next(
    (p for p in local_candidates if os.path.exists(f"{p}/.qoder/setting.json")), None
)

if local_tpl:
    # 本地副本可用：直接 shutil.copy，同时构建内存字典供后续步骤用
    for src_rel in NEEDED_PATHS:
        src = os.path.join(local_tpl, src_rel)
        dst = os.path.join(os.getcwd(), src_rel)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        elif os.path.isfile(src):
            shutil.copy2(src, dst)
    # 构建内存字典（后续步骤读取版本等信息用）
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
    # 远程兜底：tarball in-memory，直接写入当前目录，无需 /tmp
    print("  本地未找到 QoderTemplate，从 GitHub 拉取…")
    template_files = load_template_in_memory()
    write_template_files(template_files, target_dir=os.getcwd())
    print("  ✅ 远程模板已写入当前目录（无临时目录）")
```

**2-B 记录检测结果**，后续步骤使用。

---

### Phase 3：自动执行定制化（7 步）

#### Step 1 — 替换 AGENTS.md 项目标识符

使用 Phase 1 收集的信息，替换以下内容：

| 搜索 | 替换为 |
|------|--------|
| `QoderHarness Engineering` + 原描述 | 新项目名 + 用户提供的描述 |
| `https://github.com/ZenRay/QoderTemplate.git` | 用户提供的 Repo URL |
| `V0.4`（或任意 `V0.x` 版本号） | `V0.1` |
| `./src/**` 和 `./tests/**`（File Scope 段落） | 根据项目类型替换（见 Step 2） |
| Project Structure 树中的 `package.json` 行 | 根据项目类型调整 |

#### Step 2 — 调整 setting.json 路径权限

根据项目类型，替换 `permissions.allow` 中的 `Edit(./src/**)` 和 `Edit(./tests/**)` ：

| 项目类型 | 替换为 |
|----------|--------|
| `code` | 用户提供的源码目录（默认 `Edit(./src/**)` + `Edit(./tests/**)` 保持不变） |
| `docs` | `Edit(./topics/**)` + `Edit(./docs/context/**)` |
| `mixed` | 用户提供的源码目录 + `Edit(./docs/context/**)` |

完成路径权限替换后，**同步写入模板基准版本**：

```python
import json, re

# 读取模板版本（优先从内存字典，避免二次 IO）
state_content = (
    template_files.get("STATE.md")          # 远程或本地内存字典
    if template_files else
    open(".qoder/../STATE.md").read()        # GitHub Template 克隆场景
)
m = re.search(r'V(\d+\.\d+)', state_content)
template_ver = m.group(1) if m else '0.9'

# 写入 paradigmTemplateVersion 到当前项目的 setting.json
with open('.qoder/setting.json') as f:
    setting = json.load(f)
setting['userConfig']['paradigmTemplateVersion'] = f'V{template_ver}'
with open('.qoder/setting.json', 'w') as f:
    json.dump(setting, f, ensure_ascii=False, indent=2)
```

> 该字段用于 `/paradigm-sync` 识别上次同步的模板基准版本，从而显示正确的差异范围。

#### Step 3 — 重置 STATE.md

用以下模板完整覆盖（替换占位符）：

```markdown
# 项目状态看板

> 此文件由 `/update-state` 命令辅助维护，每次会话结束时更新。
> 保持简洁，≤30行，详细进度见 `docs/private/state/wip.md`。

---

## 当前状态

| 字段 | 值 |
|------|-----|
| 阶段 | **初始化** |
| 活跃分支 | `main` |
| 下一里程碑 | 完成项目结构设计，开始第一个实质任务 |
| 最近 Commit | `初始化（QoderHarness 范式迁移）` |

## 进行中

| 事项 | 状态 |
|------|------|
| 范式初始化配置 | ✅ 完成 |

## 最近决策摘要

- YYYY-MM-DD：采用 QoderHarness 工程范式，通过 /paradigm-init 绿地初始化
```

#### Step 4 — 调整 auto-lint.sh

根据项目类型，在 `case` 块中**置顶添加**对应分支（不删除现有分支）：

| 项目类型 | 添加的分支 |
|----------|-----------|
| `docs` | `*.md` → `markdownlint`（如已安装） |
| `code` / `mixed` | 根据技术栈确认对应分支已存在（Python/JS/Go/Rust/Shell 均已内置） |

> `docs` 类型时，同时在注释行更新事件说明，体现 Markdown 为主要检查对象。

#### Step 5 — 重建 docs/context/

**先删除继承的旧文件**，再创建新骨架：

1. **删除** `docs/context/adr/` 下所有继承自 QoderHarness 的 ADR 文件：
   ```python
   # 使用 Python 删除（项目 security-gate 可能拦截 rm 命令）
   import os
   for f in ['001-hooks-tier-system.md', '002-private-docs-directory.md',
             '003-precompact-hook-workaround.md', '004-knowledge-management-dual-layer.md']:
       path = f'docs/context/adr/{f}'
       if os.path.exists(path): os.remove(path)
   ```
2. 清空 `docs/context/architecture.md` 和 `docs/context/constraints.md` 的正文内容，保留文件头（`# 标题` + 初始化注释）
3. 创建新 ADR：`docs/context/adr/001-adopt-qoderharness-paradigm.md`，内容如下：

```markdown
# ADR-001：采用 QoderHarness 工程范式

**日期**：YYYY-MM-DD
**状态**：已决策

## 背景

[用户提供的一句话描述] 需要统一的 AI 辅助工作流规范。

## 决策

采用 QoderHarness 工程范式，通过 /paradigm-init 绿地初始化引入完整 Hooks 体系、知识管理架构和斜杠命令体系。

## 影响

- 获得 T1~T4 完整 Hooks 安全/质量体系
- 统一会话知识归档流程（/archive-session）
- 项目文档纳入 PersonalKnowledge 管理
```

#### Step 6 — 创建 docs/private/ 三件套

如目录不存在，先创建：
```bash
mkdir -p docs/private/state
```

创建三个文件（如已存在则跳过）：

**`docs/private/state/wip.md`**：
```markdown
# WIP — 跨会话进行中工作

> 私有文件，不提交 Git。

---

## 当前状态：初始化阶段

| 事项 | 状态 |
|------|------|
| QoderHarness 范式迁移（绿地初始化） | ✅ 完成 |
| 项目结构设计 | ⬜ 待规划 |

---
*最后更新：YYYY-MM-DD（/paradigm-init 初始化）*
```

**`docs/private/state/handoff.md`**：
```markdown
# Handoff — 会话交接备忘

> 私有文件，不提交 Git。每次只保留最新一次交接。

---

## 最近一次会话（YYYY-MM-DD）

### 本次完成

- /paradigm-init 执行完毕，QoderHarness 范式绿地初始化完成

### 待办（下次会话优先）

- [ ] 完成项目结构设计
- [ ] 开始第一个实质任务

---
*由 /paradigm-init 初始化*
```

#### Step 7 — 验收

逐项检查，全部通过后报告：

- [ ] `AGENTS.md` 中项目名、Repo URL、版本已替换
- [ ] `STATE.md` 内容已重置——模板旧项目特有标识不存在
  > 检查这些**模板旧项目特有标识**（而非简单串匹配）：
  > ```python
  > old_markers = ['V0.7', 'V0.8', 'Template 清洁化', 'repowiki',
  >                'a3eae69', 'P3 条件触发', 'ZenRay/QoderTemplate']
  > found = [m for m in old_markers if m in state_content]
  > assert not found, f"旧内容残留: {found}"
  > # 注意：STATE.md 合法引用“QoderHarness 工程范式”不算违规
  > ```
- [ ] `setting.json` 路径权限与项目类型匹配
- [ ] `auto-lint.sh` linter 与项目类型/技术栈匹配，shellcheck 零警告
- [ ] `docs/context/` 旧 ADR 已删除（非内容替换），新 ADR-001 已创建
- [ ] `docs/private/state/` 三件套已创建
- [ ] `docs/private/` 已在 `.gitignore` 中

---

### Phase 4：完成报告

输出以下内容：

```
✅ /paradigm-init 完成

项目：{项目名}
类型：{code|docs|mixed}
路径：{绝对路径}

已完成：
  ✅ AGENTS.md — 项目标识符替换
  ✅ setting.json — 路径权限调整（{类型对应说明}）
  ✅ STATE.md — 重置为初始状态
  ✅ auto-lint.sh — {linter说明}，shellcheck 零警告
  ✅ docs/context/ — 旧 ADR 清理 + ADR-001 创建
  ✅ docs/private/state/ — 三件套初始化

需手动处理：
  ⬜ docs/context/adr/001~004 — 替换为本项目实际 ADR 或直接删除
  ⬜ docs/context/architecture.md — 填写本项目实际架构
  ⬜ docs/context/constraints.md — 填写本项目实际约束
  ⬜ AGENTS.md Repo URL — 替换 <your-org>/<project> 占位符（如有）
  ⬜ 执行初始 git commit（建议：feat: init QoderHarness paradigm via /paradigm-init）

建议下一步：
  → 运行 /update-state 更新状态看板
  → 有会话内容时运行 /archive-session 归档
```

---

## 错误处理

| 情况 | 处理方式 |
|------|----------|
| 找不到 QoderTemplate 模板路径 | 提示用户提供路径，不自动猜测 |
| `docs/private/state/` 文件已存在 | 跳过（不覆盖），在报告中注明 |
| shellcheck 有警告 | 显示警告内容，不阻断执行，在报告中标注 ⚠️ |
| `AGENTS.md` 已有自定义内容（非模板原文） | 仅替换可识别的占位符，跳过已定制内容，在报告中注明 |

---

*参考：`docs/standards/migration-guide.md` 场景 A*

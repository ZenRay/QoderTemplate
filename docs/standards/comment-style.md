# 注释规范（Comment Style Guide）

> 适用范围：本项目所有代码文件
> 约束级别：AI 修改代码前**必须遵守**，Hook `auto-lint.sh` 辅助执行格式检查
> 参考设计：`docs/private/CommonThink.md` §2

---

## 语言规则

**默认英文，仅必要时用中文。**

| 场景 | 语言 | 说明 |
|------|------|------|
| 代码内联注释 | **英文** | `# check permission before redirect` |
| 函数 / 方法文档字符串 | **英文** | `"""Returns user by ID."""` |
| Shell 脚本注释 | **英文** | `# block dangerous bash commands` |
| 算法、数据结构 | **英文** | `# Binary search: O(log n)` |
| 极难用英文表达的业务规则 | **中文**（例外） | 仅在英文表达会导致歧义或严重冗长时使用 |
| 临时处理 / Workaround | **英文标记 + 必要说明** | `# FIXME: workaround for macOS sed unicode issue` |

---

## 必须注释的场景

### 1. 公共函数 / 方法（文档注释）

每个对外暴露的函数 / 方法必须包含文档注释，说明：用途、参数、返回值。

**Python 示例：**
```python
def extract_knowledge(session_content: str, project_tag: str) -> dict:
    """
    Extract structured knowledge entries from session content.

    Args:
        session_content: Raw session text to analyze.
        project_tag: Project identifier (e.g., "QoderHarness").

    Returns:
        dict: Structured data with keys: title, decisions, actions, tags.
    """
```

**Shell 示例：**
```bash
# Check whether the command matches any dangerous pattern.
# Args: $1 = full command string
# Returns: 0 = safe, 2 = block
is_dangerous_command() {
```

**JavaScript / TypeScript 示例：**
```typescript
/**
 * Archive current session content to the knowledge base.
 * @param content - Raw session text.
 * @param options - Archive options (targetDir, dryRun).
 * @returns Path to the archived file, or null when dryRun is true.
 */
async function archiveSession(content: string, options: ArchiveOptions): Promise<string | null>
```

---

### 2. 复杂算法 / 非直觉逻辑

注释说明**思路**，而非翻译代码。

```python
# Two-phase match: exact tag first, fall back to fuzzy match.
# Prevents "QoderHarness" from incorrectly matching the "Qoder" project.
result = exact_match(tag) or fuzzy_match(tag, threshold=0.8)
```

---

### 3. 业务规则硬编码

解释**为什么**是这个值，而不是这个值是什么。

```python
MAX_CONTEXT_LINES = 30  # STATE.md line limit; AI must trim old entries when exceeded
FUZZY_THRESHOLD = 0.8   # Below this similarity, topics are treated as distinct; no merge
```

---

### 4. 临时处理 / Workaround

必须说明原因和预期处理时间，避免永久遗留。

```bash
# WORKAROUND: macOS sed does not support Unicode patterns; use python3 instead.
# TODO: revert to native sed once the system version is upgraded.
python3 -c "..."
```

---

## 禁止的注释

| 禁止行为 | 原因 | 替代方案 |
|----------|------|----------|
| 注释掉废弃代码 | Git 有完整记录，注释增加噪音 | 直接删除 |
| 与代码完全重复 | 零信息量，维护成本高 | 删除或改为说明意图 |
| 过期的 TODO（>30天） | 积累技术债 | 转为 Issue，注释中附链接 |
| 无意义占位注释 | `# 开始处理` `# 结束` 等 | 删除 |

---

## Shell 脚本特殊规范

Shell 脚本（`.sh`）额外要求：

```bash
#!/bin/bash
# <filename>.sh
# Hook event: PreToolUse / PostToolUse / etc.
# Description: one-line summary of what this script does
# Exit codes: 0 = allow, 2 = block (only for blockable hook events)

set -uo pipefail  # strict mode — required in all hook scripts
```

- Every function must have a single-line summary comment
- Regex patterns must include a comment explaining the match intent
- `exit 2` must be preceded by a comment explaining the block reason

---

## Markdown 文档注释

配置文件和 Markdown 文档的关键字段需要内联说明：

```json
"userConfig": {
  "knowledgeArchive": {
    "enabled": true,          // true=写入文件；false=仅生成预览
    "targetDir": "~/Documents/PersonalKnowledge"
  }
}
```

---

## 合规检查

`auto-lint.sh` 当前执行的自动检查：

| 工具 | 覆盖范围 | 检查内容 |
|------|----------|----------|
| `shellcheck` | `.sh` 文件 | 语法、未使用变量、引用问题 |
| `eslint` | `.js/.ts` 文件 | 语法 + 部分注释规范（JSDoc） |
| `ruff` | `.py` 文件 | 语法 + docstring 格式 |
| `gofmt` | `.go` 文件 | 格式化（注释需人工审查） |

> 注释内容合规性（语言、完整性）目前依赖 AI 自律遵守，未来可通过自定义 lint 规则扩展。

---

*最后更新：2026-05-01 | 相关文件：`AGENTS.md`（强制引用）、`docs/private/CommonThink.md` §2（设计思路）*

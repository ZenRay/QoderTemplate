---
description: 按需加载 docs/context/ 下的架构文档到当前会话
---

按需读取 `docs/context/` 目录下的文档，将内容加载到当前会话 context 中。

## 用法

```
/load-context [target]
```

`target` 可选值：

| target | 读取内容 |
|--------|----------|
| `all` | 读取全部：architecture.md + constraints.md + adr/ 所有文件 |
| `arch` | 仅读取 `docs/context/architecture.md` |
| `constraints` | 仅读取 `docs/context/constraints.md` |
| `adr` | 读取 `docs/context/adr/` 下所有 ADR 文件 |
| `adr-NNN` | 读取指定编号的 ADR，如 `adr-001` |

不传 target 时默认加载 `arch` + `constraints`（最常用组合）。

## 执行步骤

**Step 1：解析 target**

根据用户输入确定要读取的文件列表：
- `all` → `docs/context/architecture.md`、`docs/context/constraints.md`、`docs/context/adr/*.md`
- `arch` → `docs/context/architecture.md`
- `constraints` → `docs/context/constraints.md`
- `adr` → `docs/context/adr/` 下所有 `.md` 文件
- `adr-NNN` → `docs/context/adr/NNN-*.md`
- 无参数 → `docs/context/architecture.md` + `docs/context/constraints.md`

**Step 2：依次读取文件**

读取所有目标文件内容，加载到当前会话。

**Step 3：汇报加载结果**

报告以下信息：
- 已加载的文件列表（含行数）
- 关键约束摘要（来自 constraints.md，若已加载）
- 当前可用 ADR 列表（若加载了 adr/）
- 提示：如需查看最新架构状态，可结合 `STATE.md` 一起参考

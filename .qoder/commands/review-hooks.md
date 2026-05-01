---
description: 审查当前项目 Hooks 配置的适用性，生成分级评估报告
---

审查 `.qoderwork/hooks/` 下所有 Hook 脚本及 `setting.json` 中的 Hooks 绑定关系，
输出适用性报告与调整建议。

## 使用场景

- 将此范式复制到新项目后**首次运行**
- 项目阶段变化（个人原型 → 团队协作 / 开发 → 生产）
- 某个 Hook 出现误触发或漏触发，需要诊断

## 执行步骤

**Step 1：读取 Hooks 绑定配置**

读取 `.qoder/setting.json` 中的 `hooks` 字段，列出所有事件→脚本绑定：
- 事件名称（UserPromptSubmit / PreToolUse / PostToolUse / Stop / PreCompact / SessionEnd）
- 绑定脚本路径
- timeout 值

**Step 2：逐脚本适用性评估**

对每个脚本按以下四个维度评估：

| 维度 | 内容 |
|------|------|
| 功能描述 | 该脚本的核心行为（一句话）|
| Tier 分级 | T1 安全 / T2 质量 / T3 体验 / T4 知识 |
| 适用性 | ✅ 保留 / ⚠️ 建议调整 / ❌ 建议移除 |
| 调整建议 | 具体需要修改的内容（若适用性非 ✅）|

**Step 3：运行 shellcheck 语法检查**

```bash
shellcheck .qoderwork/hooks/*.sh
```

汇报每个脚本的结果：通过 / 警告数 / 错误数。

**Step 4：输出结构化报告**

1. **Hooks 绑定总览**：事件 → 脚本映射表
2. **逐脚本适用性评估表**（含 Tier 分级）
3. **shellcheck 结果摘要**
4. **调整建议优先级列表**（按 T1→T4 排序）
5. 若项目类型与范式差异显著，提示运行 `hooks-reviewer` Agent 做深度分析

## 输出示例片段

```
## Hooks 适用性报告

| 脚本 | Tier | 适用性 | 建议 |
|------|------|--------|------|
| security-gate.sh | T1 | ✅ 保留 | — |
| prompt-guard.sh  | T1 | ✅ 保留 | — |
| auto-lint.sh     | T2 | ⚠️ 调整 | 当前配置了 ruff/ESLint，若项目为 Go 项目，改为 gofmt |
| log-failure.sh   | T2 | ✅ 保留 | — |
| notify-done.sh   | T3 | ✅ 保留 | — |
| knowledge-trigger.sh | T4 | ⚠️ 调整 | IDE 环境不生效，确认是否使用 CLI |

shellcheck: 6/6 通过，0 警告，0 错误
```

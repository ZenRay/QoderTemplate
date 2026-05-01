# 项目状态看板

> 此文件由 `/update-state` 命令辅助维护，每次会话结束时更新。
> 保持简洁，≤30行，详细进度见 `docs/private/state/wip.md`。

---

## 当前状态

| 字段 | 值 |
|------|-----|
| 阶段 | **V0.4 已发布，P0~P2 全部清零** |
| 活跃分支 | `master` |
| 下一里程碑 | P3（条件触发）或新需求驱动 |
| 最近 Commit | `7df05ac` — add review-hooks / hooks-reviewer / workflow.md，AGENTS.md V0.4 |

## P3 待触发事项

| 条件 | 任务 |
|------|------|
| 复制范式到新项目 | `/review-hooks`、`/new-project` |
| failure.log > 1MB | 日志轮转 |

## 最近决策摘要

- 范式完整性缺口幹平：/review-hooks 命令、hooks-reviewer Agent、workflow.md
- 工程规范文档通用化（不绑定项目/人员规模）
- docs/context/ = Layer 2，按需加载，与 Wiki 互补

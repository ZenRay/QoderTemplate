# 项目状态看板

> 此文件由 `/update-state` 命令辅助维护，每次会话结束时更新。
> 保持简洁，≤30行，详细进度见 `docs/private/state/wip.md`。

---

## 当前状态

| 字段 | 值 |
|------|-----|
| 阶段 | **V0.5 发布准备，范式可迁移性基础落地** |
| 活跃分支 | `master` |
| 下一里程碑 | GitHub Repo 设为 Template / P3 条件触发 |
| 最近 Commit | 待本次提交更新 |

## P3 待触发事项

| 条件 | 任务 |
|------|------|
| 有迁移需求 | GitHub Repo 设为 Template、`/paradigm-init` |
| failure.log > 1MB | 日志轮转 |

## 最近决策摘要

- 范式迁移体系设计落地：migration-guide.md（三场景）、CommonThink.md §5
- 范式研发期文档归入 private（知识材料管理方案.md 不再 Git 追踪）
- 范式可迁移性：A+C 轻量组合（migration-guide + GitHub Template 优先）

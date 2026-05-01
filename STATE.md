# 项目状态看板

> 此文件由 `/update-state` 命令辅助维护，每次会话结束时更新。
> 保持简洁，≤30行，详细进度见 `docs/private/state/wip.md`。

---

## 当前状态

| 字段 | 值 |
|------|-----|
| 阶段 | **V0.7 已发布，Template 清洁化全量完成** |
| 活跃分支 | `master` |
| 下一里程碑 | P3 条件触发（`/paradigm-init` 等第一次真实迁移）|
| 最近 Commit | `a3eae69` — clear repowiki, move dev-era docs to private |

## P3 待触发事项

| 条件 | 任务 |
|------|------|
| 第一次真实迁移 | `/paradigm-init` 命令 |
| failure.log > 1MB | 日志轮转 |

## 最近决策摘要

- Template 清洁化：3 个范式研发期文档移入 private、repowiki 空置占位
- 模板验证通过：48 个追踪文件均为通用内容，docs/private 仅含 .gitkeep
- 范式可迁移性 A+C 全部落地：migration-guide 已创建、GitHub Template 已开启

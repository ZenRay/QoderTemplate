# 项目状态看板

> 此文件由 `/update-state` 命令辅助维护，每次会话结束时更新。
> 保持简洁，≤30行，详细进度见 `docs/private/state/wip.md`。

---

## 当前状态

| 字段 | 值 |
|------|-----|
| 阶段 | V0.3 建设中 |
| 活跃分支 | `master` |
| 下一里程碑 | V0.3 Tag + Push |
| 最近 Commit | `25f7ceb` — repowiki + private docs 重构 |

## 活跃阻塞

- 无

## 进行中工作（P1）

- [ ] `/archive-session` 斜杠命令
- [ ] AGENTS.md 完善（指针机制 + SubAgent 广播）
- [x] STATE.md 三件套建立 ← **当前**
- [ ] `/update-state` 斜杠命令
- [ ] `docs/standards/comment-style.md`

## 最近重要决策

| 日期 | 决策 | 结论 |
|------|------|------|
| 2026-05-01 | 私有文档管理 | `docs/private/` 目录统一排除，替代逐文件 .gitignore |
| 2026-05-01 | PreCompact Hook | IDE 插件不支持，知识归档改为 `/archive-session` 主动触发 |
| 2026-04-30 | 知识管理方案 | 方案C：草稿层 `.qoder/notes/` + 精炼层 `~/Documents/PersonalKnowledge/` |

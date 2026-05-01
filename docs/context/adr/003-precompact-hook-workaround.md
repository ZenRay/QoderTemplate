# ADR-003: PreCompact Hook 归档方案替代策略

- **状态**: 已采纳
- **日期**: 2026-05-01
- **背景**: 知识归档希望在会话压缩时自动触发，但 IDE 插件不支持 PreCompact 事件

---

## 背景与问题

知识归档的理想触发时机是会话接近 context 上限时（PreCompact 事件），这样可以在信息完整的情况下自动归档。

已尝试方案：
1. 配置 `knowledge-trigger.sh` 绑定 PreCompact 事件
2. 观察 `knowledge-trigger.log`，确认完全没有触发记录

根本原因排查（通过 Guide Agent 确认）：
- **Qoder IDE 插件仅支持 5 个 Hook 事件**：UserPromptSubmit / PreToolUse / PostToolUse / PostToolUseFailure / Stop
- PreCompact 和 SessionEnd 属于 **CLI 专属事件**，在 IDE 插件模式下永远不会触发
- 这是 IDE 插件的设计限制，不是脚本配置问题

## 决策

**放弃 PreCompact 自动触发方案，改为主动触发**：
- 保留 `knowledge-trigger.sh`（供 CLI 使用时有效）
- 新增 `/archive-session` 斜杠命令，用户主动触发知识归档
- 在 AGENTS.md 上下文加载规则中记录此限制
- 归档开关通过 `setting.json → userConfig.knowledgeArchive.enabled` 控制

## 替代方案

- **Hack 绕过**：尝试将 PreCompact 逻辑绑定到其他 IDE 支持的事件 → 时机不准确，不可靠
- **定时触发**：定期运行归档 → IDE 环境中无法实现定时任务
- **每次会话结束手动执行**：太依赖人工记忆 → 引入 `/archive-session` 降低摩擦

## 影响

- 知识归档变为半主动：用户需要在合适时机主动执行 `/archive-session`
- `knowledge-trigger.sh` 保留用于未来 CLI 场景
- IDE 插件的事件限制已记录在 `docs/context/architecture.md` 和 AGENTS.md 中

# ADR-004: 知识管理双层架构与配置化开关

- **状态**: 已采纳
- **日期**: 2026-05-01
- **背景**: 需要一种既能即时捕获又能长期沉淀的知识管理方案，同时不强制每次会话都归档

---

## 背景与问题

知识管理面临两个矛盾：
1. **即时性 vs 质量**：会话中产生的想法需要立即捕获，但未经整理的内容不适合直接进入知识库
2. **强制 vs 灵活**：不是每次会话都有值得归档的内容，强制归档会产生大量低质量条目

曾考虑的方案：
- **方案A**：只用 Obsidian 本地库 → 与 AI 协作流程断裂
- **方案B**：直接写入 PersonalKnowledge → 无草稿层，质量难保证
- **方案C**：草稿层 + 精炼层双层架构 → 选择此方案
- **方案D**：独立 Git 仓库管理 → 等规模 > 50 篇再升级

## 决策

**采用方案C：双层架构 + 配置化开关**

```
草稿层: .qoder/notes/               ← 即时捕获，不提交 Git
    ↓ /archive-session 主动触发
精炼层: ~/Documents/PersonalKnowledge/   ← 结构化归档
    projects/QoderHarness/
    topics/
    areas/
```

两个独立开关（均在 `setting.json → userConfig`）：
- `knowledgeNotes.enabled`：控制草稿层（AI 是否主动创建草稿笔记）
- `knowledgeArchive.enabled`：控制精炼层写入（`false` 时 `/archive-session` 仅预览不写文件）

PersonalKnowledge 路径权限需在 `setting.json → permissions → allow` 中显式声明，否则写入时会弹出权限对话框。

## 替代方案

- **不分层，单一知识库**：缺少过滤机制，低质量内容污染知识库
- **分层但不可配置**：无法针对不同会话调整行为

## 影响

- 每次会话可按需决定是否归档
- `enabled=false` 提供安全的"预览模式"，适合测试归档内容
- PersonalKnowledge 目录结构独立演进，按 PARA 分阶段扩展（见 `规划ToDo.md` P3 条目）

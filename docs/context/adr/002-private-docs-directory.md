# ADR-002: 私有文档目录统一管理策略

- **状态**: 已采纳
- **日期**: 2026-05-01
- **背景**: 项目中存在不应提交 Git 的私有/临时文档，需要统一管理策略

---

## 背景与问题

项目中存在以下类型的私有文档：
- 个人思考记录（CommonThink.md）
- 任务规划（规划ToDo.md）
- 会话状态文件（wip.md、handoff.md）

初始方案是在 `.gitignore` 中逐文件排除，导致每新增一个私有文件都要修改 `.gitignore`，且容易遗漏。

## 决策

统一使用 `docs/private/` 目录管理所有私有/临时文档，在 `.gitignore` 中按目录排除：

```gitignore
docs/private/*
!docs/private/.gitkeep
```

目录结构：
```
docs/private/
├── .gitkeep          ← 保持目录在 Git 中存在
├── state/
│   ├── wip.md        ← 跨会话进行中工作
│   └── handoff.md    ← 单次会话交接备忘
├── CommonThink.md    ← 深度思考记录
└── 规划ToDo.md       ← 项目任务规划
```

## 替代方案

- **逐文件 .gitignore**：每次新增文件都需要修改配置，容易遗漏
- **单独仓库管理**：过度工程，私有文档量不足以支撑独立仓库

## 影响

- 新建私有文档直接放入 `docs/private/`，不需要修改 `.gitignore`
- 目录本身通过 `.gitkeep` 保持追踪，保证克隆后目录结构完整
- 公开文档放 `docs/`，按需加载文档放 `docs/context/`，规范文档放 `docs/standards/`

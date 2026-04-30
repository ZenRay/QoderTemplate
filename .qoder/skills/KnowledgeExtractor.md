# Skill: KnowledgeExtractor — 会话知识提炼归档

## 功能描述

梳理当前会话中的重要内容（背景信息、核心决策、方案对比、建议等），生成结构化
Markdown 文件，归档至个人知识库 `~/Documents/PersonalKnowledge/`。

---

## 何时使用

- 会话上下文即将压缩时（系统自动提示）
- 会话即将结束时（系统自动提示）
- 完成重要设计决策或方案讨论后（手动触发）
- 用户说"记录一下"、"归档本次会话"、"整理要点"时

---

## 执行步骤

### Step 1：确认归档路径

归档目录：`~/Documents/PersonalKnowledge/archive/YYYY/MM/`

如目录不存在，先创建：
```bash
mkdir -p ~/Documents/PersonalKnowledge/archive/$(date +%Y/%m)
```

### Step 2：分析会话内容

回顾当前会话，按以下维度提取信息：

1. **会话目标**：用户最初想解决什么问题？（一句话）
2. **项目标签**：涉及哪个项目？（用于文件命名）
3. **背景信息**：涉及的技术栈、业务上下文、已有约束
4. **核心问题**：会话中讨论的 2~5 个关键问题
5. **决策记录**：做出了哪些决定？有哪些方案对比？
6. **结论建议**：推荐做法、注意事项、可复用的模式
7. **后续行动**：明确的下一步待办事项
8. **参考资源**：提到的代码文件、外部链接、相关文档

### Step 3：生成文件名

格式：`YYYY-MM-DD_ProjectTag_主题标题.md`

示例：
- `2026-04-30_QoderHarness_工程化配置规范.md`
- `2026-05-02_ProjectA_API接口设计决策.md`
- `2026-05-05_通用_Git提交规范最佳实践.md`

**规则：**
- 日期：今天的日期
- ProjectTag：3~10字符，若内容不特定于某项目则填 `通用`
- 主题标题：10~30字符，简洁描述核心主题

### Step 4：按模板生成 Markdown 内容

```markdown
---
project: ProjectTag
topics: [主题分类1, 主题分类2]
date: YYYY-MM-DD
session_summary: 一句话描述
---

# [主题标题]

> **概述**：[一句话总结，复盘时快速判断是否需要深读]
> **项目**：ProjectTag | **日期**：YYYY-MM-DD

## 背景信息

- 项目背景：...
- 技术约束：...
- 涉及模块：...

## 核心决策

### 决策：[决策主题]

| 方案 | 优点 | 缺点 |
|------|------|------|
| 方案 A | ... | ... |
| 方案 B | ... | ... |

**选择**：方案 X
**理由**：...

## 结论与建议

- 推荐做法：...
- 注意事项：...
- 可复用的模式：...

## 后续行动

- [ ] ...

## 参考资源

- 代码文件：`...`
- 相关文档：[链接]

---
*精炼于 YYYY-MM-DD | 来源：Qoder 会话*
```

### Step 5：写入文件

将生成的 Markdown 内容写入：
```
~/Documents/PersonalKnowledge/archive/YYYY/MM/文件名.md
```

### Step 6：更新项目索引

在 `~/Documents/PersonalKnowledge/projects/{ProjectTag}/index.md` 末尾追加一行：

```markdown
- [YYYY-MM-DD] [主题标题](../../archive/YYYY/MM/文件名.md)
```

如该项目目录不存在，先创建并写入标准头部：

```markdown
# {ProjectTag} 知识集合

## 会话记录索引

- [YYYY-MM-DD] [主题标题](../../archive/YYYY/MM/文件名.md)
```

### Step 7：更新全局 README

在 `~/Documents/PersonalKnowledge/README.md` 的"最近归档"部分开头插入：

```markdown
- [YYYY-MM-DD] **ProjectTag** — [主题标题](./archive/YYYY/MM/文件名.md)
```

---

## 注意事项

- 提取内容应**基于会话已有讨论**，不需要额外调研或补充
- 保持**客观语气**，记录事实、决策和建议，而非个人评论
- 若某部分不适用（如本次没有方案对比），**标记 N/A** 而非强行填写
- 生成的文件应**可独立阅读**，不依赖会话历史
- 如果不确定 ProjectTag，询问用户

---

## 快速触发示例

用户可以直接说：
> "执行 KnowledgeExtractor，把这次讨论归档"  
> "整理本次会话要点，存到个人知识库"  
> "记录一下刚才的决策"

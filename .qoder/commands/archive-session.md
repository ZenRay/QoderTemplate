---
description: 提炼本次会话内容，归档至个人知识库
---
执行 KnowledgeExtractor Skill，对本次会话内容进行知识提炼归档。

**第一步：检查归档开关**

读取 `.qoder/setting.json` 中的 `userConfig.knowledgeArchive` 配置：
- `enabled: true` → 执行完整 7 步流程，写入 `targetDir` 指定目录
- `enabled: false` → 仅执行 Step 1-4（生成内容预览），**不写入任何文件**，在对话中展示归档内容后停止，并提示用户如需写入请将 `enabled` 改为 `true`

**第二步（enabled=true 时）：按 `.qoder/skills/KnowledgeExtractor.md` 执行完整 7 步**

1. 确认归档路径（`{targetDir}/archive/YYYY/MM/`，不存在则创建）
2. 分析本次会话内容，提取：会话目标、项目标签、背景信息、核心问题、决策记录、结论建议、后续行动、参考资源
3. 生成文件名（格式：`YYYY-MM-DD_ProjectTag_主题标题.md`）
4. 按模板生成结构化 Markdown 内容
5. 写入归档文件
6. 更新项目索引（`{targetDir}/projects/{ProjectTag}/index.md`）
7. 更新全局 README（`{targetDir}/README.md`）

**归档完成后报告：**
- 归档文件完整路径
- 文件大小
- 提取的核心决策数量
- 后续行动项数量
- 当前 `knowledgeArchive.enabled` 状态

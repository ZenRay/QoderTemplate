# Git Convention — QoderHarness Engineering

> 适用范围：本项目所有 Git 操作。
> 最后更新：2026-05-01

---

## Commit Message 格式

采用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

[body]

[footer]
```

### type（必填）

| type | 用途 | 示例 |
|------|------|------|
| `feat` | 新增功能 | `feat: add /archive-session slash command` |
| `fix` | 修复缺陷 | `fix: notify-done.sh SC2034 unused variable` |
| `docs` | 文档变更（不含代码） | `docs: add repowiki, restructure private docs` |
| `chore` | 构建/配置/工具变更 | `chore: add shellcheck to CI` |
| `refactor` | 重构（不新增功能也不修复缺陷）| `refactor: simplify security-gate pattern matching` |
| `style` | 格式调整（不影响逻辑）| `style: normalize shell script indentation` |
| `test` | 测试相关 | `test: add hook integration test cases` |
| `revert` | 撤销某次 commit | `revert: revert feat: add X` |

### scope（可选）

限定改动范围，用括号包裹。本项目常用 scope：

| scope | 含义 |
|-------|------|
| `hooks` | `.qoderwork/hooks/` 下的脚本 |
| `config` | `.qoder/setting.json` 等配置文件 |
| `docs` | `docs/` 下的文档 |
| `agents` | `AGENTS.md` 或 `.qoder/agents/` |
| `commands` | `.qoder/commands/` 下的斜杠命令 |
| `standards` | `docs/standards/` 下的规范文档 |

### subject（必填）

- 使用**英文**，首字母小写，末尾不加句号
- 动词开头，使用祈使句（`add`、`fix`、`update`，而非 `added`、`fixed`）
- 不超过 72 个字符

### body（可选）

- 空一行后追加，解释"为什么"而非"做了什么"
- 每行不超过 72 个字符

### footer（可选）

- 破坏性变更：`BREAKING CHANGE: <description>`
- 关联 Issue：`Closes #123`

---

## 实际示例（来自本项目历史）

```
feat: add docs/context/ Layer 2 architecture documents

- docs/context/architecture.md: system architecture overview, module
  descriptions, data flow, version history
- docs/context/constraints.md: technical constraints, functional
  boundaries, stability warnings, doc size limits
- docs/context/adr/001-hooks-tier-system.md: Hooks value tier framework
- AGENTS.md: add docs/context/ to project structure
```

```
fix: notify-done.sh SC2034 unused variable
```

```
docs: add repowiki, restructure private docs to docs/private/
```

---

## 分支命名规范

本项目当前为**个人单人项目**，直接在 `master` 主干开发，不需要功能分支。

若未来需要分支（协作或大型功能），遵循以下格式：

```
<type>/<short-description>
```

| 示例 | 用途 |
|------|------|
| `feat/hooks-tier4-audit` | 新功能开发 |
| `fix/security-gate-regex` | 缺陷修复 |
| `docs/context-layer2` | 文档更新 |

---

## Tag 命名规范

里程碑版本使用语义化 Tag：

```
V<major>.<minor>
```

| Tag | 对应内容 |
|-----|----------|
| `V0.1` | 初始化基础结构 |
| `V0.2` | Hooks 体系增强 + 双层知识管理 |
| `V0.3` | STATE.md 三件套 + 斜杠命令 + 注释规范 |

Tag 创建命令：
```bash
git tag -a V0.4 -m "V0.4: <一句话描述主要交付>"
git push origin --tags
```

---

## 禁止项

| 禁止 | 原因 |
|------|------|
| 禁止 `git commit -m "fix"` 等无意义消息 | 无法从历史理解变更 |
| 禁止 `git push --force` 到 master | 不可逆，协作场景会丢失他人 commit |
| 禁止提交 `docs/private/**` | 已在 .gitignore 排除，属于私有内容 |
| 禁止跳过 commit 确认直接推送 | AI 不得自行 push，需用户确认 |

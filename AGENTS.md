# Project Agent Instructions

This file provides Qoder with project-level context and behavioral guidelines.
All rules here apply to every session within this workspace.

---

## Project Overview

This is a **Qoder Harness Engineering** template project, designed as a universal paradigm
for configuring Qoder in any team project. It covers permissions, lifecycle hooks,
and agent behavior standards.

---

## Core Behavioral Rules

### Code Safety
- Always preview changes before applying edits to configuration files (`.qoder/**`, `.qoderwork/**`)
- Never delete files without explicit user confirmation
- When modifying hooks scripts, verify the exit code logic is correct

### Git Discipline
- Always run `git status` and `git diff` before committing
- Ask the user to confirm before executing `git commit` or `git push`
- Never force-push to `main` or `master` branches

### File Scope
- Source code edits are limited to `./src/**` and `./tests/**` by default
- For edits outside these paths, ask the user for confirmation first

---

## Project Structure

```
.
├── .qoder/
│   ├── agents/          # Custom sub-agent definitions
│   ├── commands/        # Custom slash commands
│   ├── skills/          # Custom skill definitions
│   ├── setting.json     # Project-level config (shared via Git)
│   └── setting.local.json  # Local overrides (not committed)
├── .qoderwork/
│   └── hooks/           # Lifecycle hook scripts
│       ├── security-gate.sh   # Blocks dangerous Bash commands
│       ├── auto-lint.sh       # Runs linter after file edits
│       └── log-failure.sh     # Logs tool execution failures
└── AGENTS.md            # This file
```

---

## Hook Scripts Reference

| Script | Event | Behavior |
|--------|-------|----------|
| `security-gate.sh` | `PreToolUse (Bash)` | Blocks `rm -rf`, `DROP TABLE`, etc. Exit 2 = block |
| `auto-lint.sh` | `PostToolUse (Write\|Edit)` | Runs ESLint/ruff/gofmt/shellcheck based on file type |
| `log-failure.sh` | `PostToolUseFailure (*)` | Appends failure records to `.qoderwork/logs/failure.log` |

---

## Communication Style

- Respond in the user's preferred language
- Keep explanations concise; use tables and code blocks for structured info
- When uncertain about scope, ask before acting

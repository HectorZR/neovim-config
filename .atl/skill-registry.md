# Skill Registry — neovim-config

**Project**: neovim-config  
**Stack**: Lua / LazyVim / Neovim configuration  
**Generated**: 2026-05-04  

---

## User Skills

| Skill | Trigger |
|-------|---------|
| brainstorming | Before any creative work — adding features, modifying behavior, building new plugins config |
| branch-pr | When creating a pull request or preparing changes for review |
| issue-creation | When creating a GitHub issue, reporting a bug, or requesting a feature |
| judgment-day | "judgment day", "dual review", "review adversarial", "juzgar" |
| skill-creator | When creating a new skill or documenting patterns for AI |
| skill-registry | "update skills", "skill registry", "actualizar skills" |
| solid | When writing code, implementing features, refactoring, or reviewing code |

## Compact Rules

### brainstorming
Before implementing any feature or config change, explore the user's intent first. Ask: What behavior do you want? Does LazyVim already provide this? What's the minimal change? Present design options before writing code.

### branch-pr
Follow issue-first: reference the issue in the PR. Keep PR title short (<70 chars). Use HEREDOC for PR body. Include test plan (manual Neovim verification steps).

### issue-creation
Create GitHub issues with clear title, problem statement, and expected behavior. Reference plugin names and LazyVim context where relevant.

### solid
Apply SOLID principles to Lua plugin specs. Each plugin file has one responsibility. Don't mix unrelated plugin configs. Prefer `opts` merging over full spec replacement. No deep nesting, small functions.

### judgment-day
Launch two independent blind judge sub-agents simultaneously to review the same target. Synthesize findings, apply fixes, re-judge until both pass or escalate after 2 iterations.

## Project Conventions

- **Convention file**: `CLAUDE.md` (project root)
- **Formatter**: StyLua — `stylua lua/` (2-space indent, 120-col width, see `stylua.toml`)
- **Pattern**: Each `lua/plugins/*.lua` returns a lazy.nvim spec table
- **Override pattern**: match plugin by name + merge via `opts = function(_, opts) ... end`
- **No test infrastructure**: this is a Neovim config — no automated tests
